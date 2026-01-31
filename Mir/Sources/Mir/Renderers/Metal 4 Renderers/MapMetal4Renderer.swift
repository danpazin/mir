// MapMetal4Renderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

final class MapMetal4Renderer: Renderer {

    // MARK: - Properties

    /// The Metal device used to create and manage GPU resources.
    let device: MTLDevice
    // Temp
    let mesh: MTKMesh!
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    let commandQueue: (any MTL4CommandQueue)?
    /// The render pipeline state used to encode draw calls.
    var renderPipelineState: MTLRenderPipelineState?
    /// A residency set that keeps resources in memory for the app's lifetime.
    var residencySet: MTLResidencySet?
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

        // Temp
        // 1
        let allocator = MTKMeshBufferAllocator(device: device)
        // 2
        let mdlMesh = MDLMesh(
            sphereWithExtent: [0.75, 0.75, 0.75],
            segments: [30, 30],
            inwardNormals: false,
            geometryType: .triangles,
            allocator: allocator)
        // 3
        let mesh = try! MTKMesh(mesh: mdlMesh, device: device)
        self.mesh = mesh

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
            let commandQueue
        else {
            return
        }
        // Prepare to use or reuse the allocator by resetting it.
        commandAllocator.reset()
        // Prepare to use or reuse the command buffer for the frame's commands.
        commandBuffer.beginCommandBuffer(allocator: commandAllocator)
        // Create a render pass encoder from the command buffer with the view's configuration.
        guard let renderPassDescriptor = view.currentMTL4RenderPassDescriptor,
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        // Configure the encoder with the renderer's main pipeline state.
        renderEncoder.setRenderPipelineState(renderPipelineState)
        // Bind vertex buffer GPU address at index 0 (matches shader layout)
        argumentTable.setAddress(mesh.vertexBuffers[0].buffer.gpuAddress, index: 0)
        renderEncoder.setArgumentTable(argumentTable, stages: .vertex)
        // Draw the first submesh (temporary)
        if let submesh = mesh.submeshes.first {
            renderEncoder.drawIndexedPrimitives(
                primitiveType: .triangle,
                indexCount: submesh.indexCount,
                indexType: submesh.indexType,
                indexBuffer: submesh.indexBuffer.buffer.gpuAddress,
                indexBufferLength: submesh.indexBuffer.length
            )
        }
        // Finalize the render pass
        renderEncoder.endEncoding()
        // End and submit the command buffer to the GPU
        commandBuffer.endCommandBuffer()
        /// A drawable from the view that the method renders the frame to.
        let drawable = view.currentDrawable
        guard let drawable else { return }
        // Instruct the queue to wait until the drawable is ready to receive output from the render pass.
        commandQueue.waitForDrawable(drawable)
        // Run the command buffer on the GPU by submitting it the Metal device's queue.
        commandQueue.commit([commandBuffer])
        // Notify the drawable that the GPU is done running the render pass.
        commandQueue.signalDrawable(drawable)
        // Instruct the drawable to show itself on the device's display when the render pass completes.
        drawable.present()
    }
}
