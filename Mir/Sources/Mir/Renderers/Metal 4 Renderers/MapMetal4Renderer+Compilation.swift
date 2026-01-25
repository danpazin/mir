// MapMetal4Renderer+Compilation.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetal4Renderer {
    
    func compileRenderPipeline(colorPixelFormat: MTLPixelFormat) throws {
        let compiler = try createCompiler()
        let renderPipelineDescriptor = try configureRenderPipeline(colorPixelFormat: colorPixelFormat)
        renderPipelineState = try compiler.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
    }
    
    /// Creates a Metal 4 compiler for compiling render pipelines.
    ///
    /// This method initializes a Metal 4 compiler with default settings that will be used
    /// to compile shader functions and render pipeline states.
    ///
    /// - Returns: A configured `MTL4Compiler` instance.
    /// - Throws: An error if the compiler cannot be created from the Metal device.
    private func createCompiler() throws -> some MTL4Compiler {
        let compilerDescriptor = MTL4CompilerDescriptor()
        let compiler = try device.makeCompiler(descriptor: compilerDescriptor)
        return compiler
    }
    
    /// Configures a render pipeline descriptor for Metal 4 rendering.
    ///
    /// This method creates and configures a `MTL4RenderPipelineDescriptor` by:
    /// - Loading the default Metal shader library
    /// - Setting up vertex and fragment shader function descriptors
    /// - Configuring the color attachment pixel format
    /// - Setting the vertex descriptor from the mesh
    ///
    /// - Parameter colorPixelFormat: The pixel format for the color attachment.
    /// - Returns: A configured `MTL4RenderPipelineDescriptor` ready for pipeline creation.
    /// - Throws: An error if the shader library cannot be loaded.
    private func configureRenderPipeline(colorPixelFormat: MTLPixelFormat) throws -> MTL4RenderPipelineDescriptor {
        // Load the app's default Metal shader library (contains vertex/fragment functions).
        let library = try device.makeDefaultLibrary(bundle: .module)
        let vertexFunctionDescriptor = makeVertexShaderConfiguration(library: library)
        let fragmentFunctionDescriptor = makeFragmentShaderConfiguration(library: library)
        // Create a pipeline descriptor that describes how the GPU should render.
        let renderPipelineDescriptor = MTL4RenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunctionDescriptor = vertexFunctionDescriptor
        renderPipelineDescriptor.fragmentFunctionDescriptor = fragmentFunctionDescriptor
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor) // temp
        return renderPipelineDescriptor
    }
    
    /// Creates and configures a vertex shader function descriptor.
    ///
    /// This method sets up the function descriptor for the vertex shader by specifying
    /// the Metal library containing the shader and the function name.
    ///
    /// - Parameter library: The Metal library containing the vertex shader function.
    /// - Returns: A configured `MTL4LibraryFunctionDescriptor` for the vertex shader.
    private func makeVertexShaderConfiguration(library: MTLLibrary) -> MTL4LibraryFunctionDescriptor {
        let vertexFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        vertexFunctionDescriptor.library = library
        vertexFunctionDescriptor.name = "vertexShader"
        return vertexFunctionDescriptor
    }
    
    /// Creates and configures a fragment shader function descriptor.
    ///
    /// This method sets up the function descriptor for the fragment shader by specifying
    /// the Metal library containing the shader and the function name.
    ///
    /// - Parameter library: The Metal library containing the fragment shader function.
    /// - Returns: A configured `MTL4LibraryFunctionDescriptor` for the fragment shader.
    private func makeFragmentShaderConfiguration(library: MTLLibrary) -> MTL4LibraryFunctionDescriptor {
        let fragmentFunctionDescriptor = MTL4LibraryFunctionDescriptor()
        fragmentFunctionDescriptor.library = library
        fragmentFunctionDescriptor.name = "fragmentShader"
        return fragmentFunctionDescriptor
    }
}
