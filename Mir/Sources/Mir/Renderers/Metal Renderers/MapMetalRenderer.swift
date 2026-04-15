// MapMetalRenderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit
import MirSharedTypes

final class MapMetalRenderer: Renderer {
    
    // MARK: - Properties

    /// The Metal device used to create and manage GPU resources.
    let device: MTLDevice
    /// The render pipeline state used to encode draw calls.
    var renderPipelineState: MTLRenderPipelineState?
    /// The scene that holds the camera and objects to render.
    var scene = Scene()
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    private let commandQueue: MTLCommandQueue?
    // temp
    let mesh: MTKMesh!

    // MARK: - Initializers
    
    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
        
        // temp
        let allocator = MTKMeshBufferAllocator(device: device)
        let mdlMesh = MDLMesh(
          sphereWithExtent: [0.75, 0.75, 0.75],
          segments: [30, 30],
          inwardNormals: false,
          geometryType: .triangles,
          allocator: allocator)
        let mesh = try! MTKMesh(mesh: mdlMesh, device: device)
        self.mesh = mesh
    }
    
    // MARK: - Renderer
    
    func renderFrame(to view: MTKView) {
        guard
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
            let renderPipelineState,
            let drawable = view.currentDrawable
        else {
            return
        }
        // Configure the encoder with the renderer's main pipeline state.
        renderEncoder.setRenderPipelineState(renderPipelineState)
        var uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: scene.camera.viewMatrix,
            projectionMatrix: scene.camera.projectionMatrix
        )
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0) // temp
        renderEncoder.setTriangleFillMode(.lines) // temp
        let submesh = mesh.submeshes.first! // temp
        // Draw the sphere
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: 0
        ) // temp
        // Finalize the render pass
        renderEncoder.endEncoding()
        // Instruct the drawable to show itself on the device's display when the render pass completes.
        commandBuffer.present(drawable)
        // Submit the command buffer to the GPU
        commandBuffer.commit()
    }
}
