// MapMetal4Renderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

// The Simulator SDK doesn't include Metal 4, so this renderer only builds for devices and Macs.
#if !targetEnvironment(simulator)

import MetalKit
import MirSharedTypes

package final class MapMetal4Renderer: Renderer {

    // MARK: - Properties

    /// The Metal device used to create and manage GPU resources.
    package let device: MTLDevice
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    let commandQueue: (any MTL4CommandQueue)?
    /// The render pipeline state used to encode draw calls.
    package var renderPipelineState: MTLRenderPipelineState?
    /// A residency set that keeps resources in memory for the app's lifetime.
    var residencySet: MTLResidencySet?
    /// A shared buffer that holds the per-frame uniform data (matrices) for the vertex shader.
    let uniformBuffer: MTLBuffer?
    /// A shared buffer that holds the vertex data for all globe patches, structured as a flat array of float3 positions.
    let globeBuffer: MTLBuffer?
    /// The scene that holds the camera and objects to render.
    package var scene = Scene()
    /// The current Metal 4 command buffer used to encode and submit GPU work for a frame.
    private let commandBuffer: MTL4CommandBuffer?
    /// An object that stores commands for each frame while the app encodes them and the GPU runs them.
    private let commandAllocator: MTL4CommandAllocator?
    /// An argument table that stores the resource bindings for a render encoder.
    private var argumentTable: MTL4ArgumentTable?
    /// An event the GPU signals when it finishes an offscreen frame.
    private let frameEvent: MTLSharedEvent?
    /// The value ``frameEvent`` reaches when the latest offscreen frame finishes.
    private var frameEventValue: UInt64 = 0
    /// The offscreen texture currently in the residency set.
    private var offscreenTexture: MTLTexture?

    // MARK: - Initializers

    package init(device: MTLDevice) throws {
        self.device = device
        commandQueue = device.makeMTL4CommandQueue()
        commandBuffer = device.makeCommandBuffer()
        commandAllocator = device.makeCommandAllocator()
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
        globeBuffer = device.makeBuffer(length: MemoryLayout<InlineArray<3, SIMD3<Float>>>.stride * scene.globe.patches.count)
        frameEvent = device.makeSharedEvent()
        argumentTable = try makeArgumentTable()
        residencySet = try makeResidencySet()
        setUpResidency()
    }

    // MARK: - Renderer

    package func renderFrame(to view: MTKView) {
        guard
            let commandQueue,
            let commandBuffer,
            let renderPassDescriptor = view.currentMTL4RenderPassDescriptor,
            let drawable = view.currentDrawable
        else {
            return
        }
        do {
            try encodeFrame(renderPassDescriptor: renderPassDescriptor)
        } catch {
            return
        }
        commandQueue.waitForDrawable(drawable)
        commandQueue.commit([commandBuffer])
        commandQueue.signalDrawable(drawable)
        drawable.present()
    }

    package func renderFrame(into texture: MTLTexture) throws {
        guard let commandQueue, let commandBuffer, let frameEvent else {
            throw RendererError.encodingUnavailable
        }
        makeResident(texture)
        let renderPassDescriptor = MTL4RenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        try encodeFrame(renderPassDescriptor: renderPassDescriptor)
        frameEventValue += 1
        commandQueue.commit([commandBuffer])
        commandQueue.signalEvent(frameEvent, value: frameEventValue)
        guard frameEvent.wait(untilSignaledValue: frameEventValue, timeoutMS: 5_000) else {
            throw RendererError.gpuTimeout
        }
    }

    // MARK: - Encoding

    /// Encodes the scene's draw calls into the command buffer.
    ///
    /// Both ``renderFrame(to:)`` and ``renderFrame(into:)`` call this, so offscreen tests and
    /// benchmarks exercise exactly the work the view does.
    private func encodeFrame(renderPassDescriptor: MTL4RenderPassDescriptor) throws {
        guard
            let commandBuffer,
            let commandAllocator,
            let renderPipelineState,
            let argumentTable,
            let uniformBuffer,
            let globeBuffer
        else {
            throw RendererError.encodingUnavailable
        }
        commandAllocator.reset()
        commandBuffer.beginCommandBuffer(allocator: commandAllocator)
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            commandBuffer.endCommandBuffer()
            throw RendererError.encodingUnavailable
        }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        // Globe triangles wind counter-clockwise seen from outside; Metal treats clockwise as front-facing by default.
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        let uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: simd_float4x4(scene.camera.viewMatrix),
            projectionMatrix: simd_float4x4(scene.camera.projectionMatrix)
        )
        uniformBuffer.contents().storeBytes(of: uniforms, as: Uniforms.self)
        // Flatten patch vertices into contiguous GPU input expected by `vertexShader`.
        var vertices: [SIMD3<Float>] = []
        vertices.reserveCapacity(scene.globe.patches.count * 3)
        for i in scene.globe.patches.indices {
            for j in scene.globe.patches[i].vertices.indices {
                vertices.append(scene.globe.patches[i].vertices[j])
            }
        }
        let vertexByteCount = vertices.count * MemoryLayout<SIMD3<Float>>.stride
        guard vertexByteCount <= globeBuffer.length else {
            renderEncoder.endEncoding()
            commandBuffer.endCommandBuffer()
            throw RendererError.bufferTooSmall(needed: vertexByteCount, available: globeBuffer.length)
        }
        vertices.withUnsafeBytes { ptr in
            globeBuffer.contents().copyMemory(from: ptr.baseAddress!, byteCount: ptr.count)
        }
        argumentTable.setAddress(globeBuffer.gpuAddress, index: 0)
        argumentTable.setAddress(uniformBuffer.gpuAddress, index: 1)
        renderEncoder.setArgumentTable(argumentTable, stages: .vertex)
        renderEncoder.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder.endEncoding()
        commandBuffer.endCommandBuffer()
    }

    // MARK: - Residency

    /// Adds an offscreen texture to the residency set, replacing the previous one.
    ///
    /// Metal 4 only lets the GPU access resources in a residency set the queue knows about.
    private func makeResident(_ texture: MTLTexture) {
        guard let residencySet, offscreenTexture !== texture else { return }
        if let offscreenTexture {
            residencySet.removeAllocation(offscreenTexture)
        }
        residencySet.addAllocation(texture)
        residencySet.commit()
        offscreenTexture = texture
    }
}
#endif
