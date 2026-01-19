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
    private let device: MTLDevice
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    private let commandQueue: MTL4CommandQueue?
    /// The current Metal 4 command buffer used to encode and submit GPU work for a frame.
    private let commandBuffer: MTL4CommandBuffer?
    
    // MARK: - Initializers
    
    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeMTL4CommandQueue()
        commandBuffer = device.makeCommandBuffer()
    }
    
    // MARK: - Renderer
    
    func compileRenderPipeline(colorPixelFormat: MTLPixelFormat) throws {
        
    }
    
    func renderFrame(to view: MTKView) {
        guard
            let renderPassDescriptor = view.currentMTL4RenderPassDescriptor,
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }
              
    }
}
