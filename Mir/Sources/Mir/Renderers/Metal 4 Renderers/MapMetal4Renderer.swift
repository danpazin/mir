// MapMetal4Renderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit
import MirSharedTypes

final class MapMetal4Renderer: Renderer {

    // MARK: - Properties

    /// The Metal device used to create and manage GPU resources.
    let device: MTLDevice
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    let commandQueue: (any MTL4CommandQueue)?
    /// The render pipeline state used to encode draw calls.
    var renderPipelineState: MTLRenderPipelineState?
    /// A residency set that keeps resources in memory for the app's lifetime.
    var residencySet: MTLResidencySet?
    /// A shared buffer that holds the per-frame uniform data (matrices) for the vertex shader.
    let uniformBuffer: MTLBuffer?
    /// A shared buffer that holds the vertex data for all globe patches, structured as a flat array of float3 positions.
    let globeBuffer: MTLBuffer?
    /// The scene that holds the camera and objects to render.
    var scene = Scene()
    /// The current Metal 4 command buffer used to encode and submit GPU work for a frame.
    private let commandBuffer: MTL4CommandBuffer?
    /// An object that stores commands for each frame while the app encodes them and the GPU runs them.
    private let commandAllocator: MTL4CommandAllocator?
    /// An argument table that stores the resource bindings for a render encoder.
    private var argumentTable: MTL4ArgumentTable?

    // MARK: - Initializers

    init(device: MTLDevice) throws {
        self.device = device
        commandQueue = device.makeMTL4CommandQueue()
        commandBuffer = device.makeCommandBuffer()
        commandAllocator = device.makeCommandAllocator()
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
        globeBuffer = device.makeBuffer(length: MemoryLayout<InlineArray<3, SIMD3<Float>>>.stride * scene.globe.patches.count)
        argumentTable = try makeArgumentTable()
        residencySet = try makeResidencySet()
        setUpResidency()
    }

    // MARK: - Renderer

    func renderFrame(to view: MTKView) {
        guard
            let commandBuffer,
            let commandAllocator,
            let renderPipelineState,
            let argumentTable,
            let commandQueue,
            let uniformBuffer,
            let globeBuffer,
            let drawable = view.currentDrawable
        else {
            return
        }
        commandAllocator.reset()
        commandBuffer.beginCommandBuffer(allocator: commandAllocator)
        guard let renderPassDescriptor = view.currentMTL4RenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setCullMode(.back)
        let uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: scene.camera.viewMatrix,
            projectionMatrix: scene.camera.projectionMatrix
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
        vertices.withUnsafeBytes { ptr in
            globeBuffer.contents().copyMemory(from: ptr.baseAddress!, byteCount: ptr.count)
        }
        argumentTable.setAddress(globeBuffer.gpuAddress, index: 0)
        argumentTable.setAddress(uniformBuffer.gpuAddress, index: 1)
        renderEncoder.setArgumentTable(argumentTable, stages: .vertex)
        renderEncoder.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: vertices.count)
        renderEncoder.endEncoding()
        commandBuffer.endCommandBuffer()
        commandQueue.waitForDrawable(drawable)
        commandQueue.commit([commandBuffer])
        commandQueue.signalDrawable(drawable)
        drawable.present()
    }
}
