// MapMetal4Renderer+Compilation.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetal4Renderer {

    /// Compiles and stores the render pipeline state used by this renderer.
    ///
    /// Call this method during renderer setup (for example, when you create/configure the `MTKView`)
    /// and whenever the render target’s pixel format changes.
    ///
    /// The resulting pipeline state is stored in ``renderPipelineState`` and should be reused for
    /// subsequent frames. Pipeline compilation can be relatively expensive, so avoid calling this
    /// method from the per-frame rendering path.
    ///
    /// - Parameter colorPixelFormat: The pixel format of the render target’s color attachment
    ///   (typically `MTKView.colorPixelFormat`).
    /// - Throws: An error if Metal can’t create the pipeline state. Common reasons include missing shader
    ///   functions in the default library or an incompatible render pipeline descriptor.
    func compileRenderPipeline(colorPixelFormat: MTLPixelFormat) throws {
        let compiler = try makeCompiler()
        let renderPipelineDescriptor = try configureRenderPipeline(colorPixelFormat: colorPixelFormat)
        let renderPipelineState = try compiler.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        self.renderPipelineState = renderPipelineState
    }

    /// Makes a Metal 4 compiler for compiling render pipelines.
    ///
    /// This method initializes a Metal 4 compiler with default settings that will be used
    /// to compile shader functions and render pipeline states.
    ///
    /// - Returns: A configured `MTL4Compiler` instance.
    /// - Throws: An error if the compiler cannot be made from the Metal device.
    private func makeCompiler() throws -> some MTL4Compiler {
        let compilerDescriptor = MTL4CompilerDescriptor()
        let compiler = try device.makeCompiler(descriptor: compilerDescriptor)
        return compiler
    }

    /// Configures a render pipeline descriptor for Metal 4 rendering.
    ///
    /// This method makes and configures a `MTL4RenderPipelineDescriptor` by:
    /// - Loading the default Metal shader library
    /// - Setting up vertex and fragment shader function descriptors
    /// - Configuring the color attachment pixel format
    /// - Setting the vertex descriptor from the mesh
    ///
    /// - Parameter colorPixelFormat: The pixel format for the color attachment.
    /// - Returns: A configured `MTL4RenderPipelineDescriptor` ready for pipeline making.
    /// - Throws: An error if the shader library cannot be loaded.
    private func configureRenderPipeline(colorPixelFormat: MTLPixelFormat) throws -> MTL4RenderPipelineDescriptor {
        // Load the app's default Metal shader library (contains vertex/fragment functions).
        let library = try device.makeDefaultLibrary(bundle: .module)
        let vertexFunctionDescriptor = makeVertexShaderConfiguration(library: library)
        let fragmentFunctionDescriptor = makeFragmentShaderConfiguration(library: library)
        // Make a pipeline descriptor that describes how the GPU should render.
        let renderPipelineDescriptor = MTL4RenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunctionDescriptor = vertexFunctionDescriptor
        renderPipelineDescriptor.fragmentFunctionDescriptor = fragmentFunctionDescriptor
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor) // temp
        return renderPipelineDescriptor
    }

    /// Makes and configures a vertex shader function descriptor.
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

    /// Makes and configures a fragment shader function descriptor.
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
