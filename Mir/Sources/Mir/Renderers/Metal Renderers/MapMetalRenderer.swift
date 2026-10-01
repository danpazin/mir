// MapMetalRenderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit
import MirSharedTypes

package final class MapMetalRenderer: Renderer {

    // MARK: - Properties

    /// The Metal device used to create and manage GPU resources.
    package let device: MTLDevice
    /// The render pipeline state used to encode draw calls.
    package var renderPipelineState: MTLRenderPipelineState?
    /// The scene that holds the camera and objects to render.
    package var scene: Scene
    /// The work the most recently encoded frame asked of the GPU.
    package private(set) var lastFrameStatistics = FrameStatistics()
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    private let commandQueue: MTLCommandQueue?
    /// A buffer with every globe vertex, as the flat float3 array `vertexShader` reads.
    private var globeBuffer: MTLBuffer?
    /// The subdivision level of the globe in ``globeBuffer``, if any.
    private var uploadedSubdivisionLevel: Int?

    // MARK: - Initializers

    package init(device: MTLDevice, scene: Scene = Scene()) {
        self.device = device
        self.scene = scene
        commandQueue = device.makeCommandQueue()
    }

    // MARK: - Renderer

    package func renderFrame(to view: MTKView) {
        guard
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let drawable = view.currentDrawable
        else {
            return
        }
        do {
            try encodeFrame(into: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        } catch {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    @discardableResult
    package func renderFrame(into texture: MTLTexture) throws -> FrameTiming {
        let clock = ContinuousClock()
        let start = clock.now
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            throw RendererError.encodingUnavailable
        }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        try encodeFrame(into: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        let encoded = clock.now
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        let finished = clock.now
        if let error = commandBuffer.error {
            throw RendererError.gpuFailure(description: error.localizedDescription)
        }
        return FrameTiming(
            encodeSeconds: (encoded - start).inSeconds,
            gpuSeconds: commandBuffer.gpuEndTime - commandBuffer.gpuStartTime,
            totalSeconds: (finished - start).inSeconds
        )
    }

    // MARK: - Encoding

    /// Encodes the scene's draw calls into a render pass.
    ///
    /// Both ``renderFrame(to:)`` and ``renderFrame(into:)`` call this, so offscreen tests and
    /// benchmarks exercise exactly the work the view does.
    private func encodeFrame(into commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) throws {
        guard let renderPipelineState else {
            throw RendererError.encodingUnavailable
        }
        let globe = try globeVertexBuffer()
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            throw RendererError.encodingUnavailable
        }
        let signpost = Signposts.renderer.beginInterval("Encode frame")
        defer { Signposts.renderer.endInterval("Encode frame", signpost) }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        // Globe triangles wind counter-clockwise seen from outside; Metal treats clockwise as front-facing by default.
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        var uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: simd_float4x4(scene.camera.viewMatrix),
            projectionMatrix: simd_float4x4(scene.camera.projectionMatrix)
        )
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        renderEncoder.setVertexBuffer(globe.buffer, offset: 0, index: 0)
        let vertexCount = scene.globe.patches.count * 3
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        var statistics = FrameStatistics()
        statistics.drawCalls = 1
        statistics.vertexCount = vertexCount
        statistics.uploadedBytes = MemoryLayout<Uniforms>.stride + globe.uploadedBytes
        lastFrameStatistics = statistics
    }

    /// Returns a buffer with every globe vertex, making a new one only when the globe has changed.
    ///
    /// One buffer lets one draw call render the whole globe. Before, each of the 20 × 4^level
    /// patches was its own draw call with its own vertex bytes: 81,920 draws and 3.8 ms of CPU
    /// encode time per frame at level 6.
    ///
    /// - Returns: The buffer, and the number of bytes copied for this frame.
    private func globeVertexBuffer() throws -> (buffer: MTLBuffer, uploadedBytes: Int) {
        if let globeBuffer, uploadedSubdivisionLevel == scene.globe.subdivisionLevel {
            return (globeBuffer, 0)
        }
        // Flatten patch vertices into the contiguous float3 array `vertexShader` reads.
        var vertices: [SIMD3<Float>] = []
        vertices.reserveCapacity(scene.globe.patches.count * 3)
        for patch in scene.globe.patches {
            for corner in patch.vertices.indices {
                vertices.append(patch.vertices[corner])
            }
        }
        let byteCount = vertices.count * MemoryLayout<SIMD3<Float>>.stride
        guard let buffer = device.makeBuffer(bytes: vertices, length: byteCount, options: .storageModeShared) else {
            throw RendererError.encodingUnavailable
        }
        globeBuffer = buffer
        uploadedSubdivisionLevel = scene.globe.subdivisionLevel
        return (buffer, byteCount)
    }
}
