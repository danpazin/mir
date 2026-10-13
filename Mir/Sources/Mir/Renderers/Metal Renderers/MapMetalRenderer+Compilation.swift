// MapMetalRenderer+Compilation.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetalRenderer {
    
    func compileRenderPipeline(colorPixelFormat: MTLPixelFormat) throws {
        let renderPipelineDescriptor = try configureRenderPipeline(colorPixelFormat: colorPixelFormat)
        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        self.renderPipelineState = renderPipelineState
    }
    
    private func configureRenderPipeline(colorPixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineDescriptor {
        let library = try device.makeDefaultLibrary(bundle: .module)
        guard let vertexFunction = library.makeFunction(name: "vertexShader") else {
            throw RendererError.missingVertexFunction(name: "vertexShader")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            throw RendererError.missingFragmentFunction(name: "fragmentShader")
        }
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        return renderPipelineDescriptor
    }
}
