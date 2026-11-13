// MapMetalRenderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit
import MirSharedTypes

/// Draws the map with the classic Metal API, for GPUs and simulators without Metal 4.
final class MapMetalRenderer: Renderer {
    
    // MARK: - Properties

    /// The GPU the renderer draws with.
    let device: MTLDevice
    /// The compiled shaders and settings for drawing the globe, or nil until they're compiled.
    var renderPipelineState: MTLRenderPipelineState?
    /// The camera and the globe to draw.
    var scene = Scene()
    /// The queue that sends each frame's commands to the GPU.
    private let commandQueue: MTLCommandQueue?

    // MARK: - Initializers
    
    /// Creates a renderer that draws with the given GPU.
    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
    }
    
    // MARK: - Renderer
    
    /// Draws the globe into the view's next drawable, one triangle per draw call, and presents it.
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
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        var uniforms = Uniforms(camera: scene.camera, drawableSize: view.drawableSize)
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        for i in scene.globe.patches.indices {
            var vertices = scene.globe.patches[i].vertices
            renderEncoder.setVertexBytes(&vertices, length: MemoryLayout<SIMD3<Float>>.stride * 3, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
        }
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
