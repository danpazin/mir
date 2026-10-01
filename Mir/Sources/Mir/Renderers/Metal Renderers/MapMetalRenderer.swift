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
    package var scene = Scene()
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    private let commandQueue: MTLCommandQueue?

    // MARK: - Initializers

    package init(device: MTLDevice) {
        self.device = device
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

    package func renderFrame(into texture: MTLTexture) throws {
        guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
            throw RendererError.encodingUnavailable
        }
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        try encodeFrame(into: commandBuffer, renderPassDescriptor: renderPassDescriptor)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        if let error = commandBuffer.error {
            throw RendererError.gpuFailure(description: error.localizedDescription)
        }
    }

    // MARK: - Encoding

    /// Encodes the scene's draw calls into a render pass.
    ///
    /// Both ``renderFrame(to:)`` and ``renderFrame(into:)`` call this, so offscreen tests and
    /// benchmarks exercise exactly the work the view does.
    private func encodeFrame(into commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) throws {
        guard
            let renderPipelineState,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            throw RendererError.encodingUnavailable
        }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setCullMode(.back)
        var uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: simd_float4x4(scene.camera.viewMatrix),
            projectionMatrix: simd_float4x4(scene.camera.projectionMatrix)
        )
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        for i in scene.globe.patches.indices {
            var vertices = scene.globe.patches[i].vertices
            renderEncoder.setVertexBytes(&vertices, length: MemoryLayout<SIMD3<Float>>.stride * 3, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        }
        renderEncoder.endEncoding()
    }
}
