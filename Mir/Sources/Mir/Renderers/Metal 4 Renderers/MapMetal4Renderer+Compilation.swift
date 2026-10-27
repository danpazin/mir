// MapMetal4Renderer+Compilation.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetal4Renderer {

    func compileRenderPipeline(colorPixelFormat: MTLPixelFormat) throws {
        let compiler = try makeCompiler()
        let renderPipelineDescriptor = try configureRenderPipeline(colorPixelFormat: colorPixelFormat)
        let renderPipelineState = try compiler.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        self.renderPipelineState = renderPipelineState
    }

    private func makeCompiler() throws -> some MTL4Compiler {
        let compilerDescriptor = MTL4CompilerDescriptor()
        let compiler = try device.makeCompiler(descriptor: compilerDescriptor)
        return compiler
    }

    /// Vertex data layout is provided at draw time through argument-table buffer bindings.
    private func configureRenderPipeline(colorPixelFormat: MTLPixelFormat) throws -> MTL4RenderPipelineDescriptor {
        let library = try device.makeDefaultLibrary(bundle: .module)
        let vertexFunctionDescriptor = makeVertexShaderConfiguration(library: library)
        let fragmentFunctionDescriptor = makeFragmentShaderConfiguration(library: library)
        let renderPipelineDescriptor = MTL4RenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunctionDescriptor = vertexFunctionDescriptor
        renderPipelineDescriptor.fragmentFunctionDescriptor = fragmentFunctionDescriptor
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        return renderPipelineDescriptor
    }

    private func makeVertexShaderConfiguration(library: MTLLibrary) -> MTL4LibraryFunctionDescriptor {
        let vertexFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        vertexFunctionDescriptor.library = library
        vertexFunctionDescriptor.name = "vertexShader"
        return vertexFunctionDescriptor
    }

    private func makeFragmentShaderConfiguration(library: MTLLibrary) -> MTL4LibraryFunctionDescriptor {
        let fragmentFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        fragmentFunctionDescriptor.library = library
        fragmentFunctionDescriptor.name = "fragmentShader"
        return fragmentFunctionDescriptor
    }
}
