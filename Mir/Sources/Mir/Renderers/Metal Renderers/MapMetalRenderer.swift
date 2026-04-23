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

    // MARK: - Initializers
    
    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
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
        renderEncoder.setCullMode(.back)
        var uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: scene.camera.viewMatrix,
            projectionMatrix: scene.camera.projectionMatrix
        )
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        // Draw the globe.
        for i in scene.globe.patches.indices {
            var vertices = scene.globe.patches[i].vertices
            renderEncoder.setVertexBytes(&vertices, length: MemoryLayout<SIMD3<Float>>.stride * 3, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        }
        // Finalize the render pass.
        renderEncoder.endEncoding()
        // Instruct the drawable to show itself on the device's display when the render pass completes.
        commandBuffer.present(drawable)
        // Submit the command buffer to the GPU.
        commandBuffer.commit()
    }
}
