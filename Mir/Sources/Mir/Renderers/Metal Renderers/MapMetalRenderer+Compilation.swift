// MapMetalRenderer+Compilation.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetalRenderer {
    
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
        let renderPipelineDescriptor = try configureRenderPipeline(colorPixelFormat: colorPixelFormat)
        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        self.renderPipelineState = renderPipelineState
    }
    
    /// Configures and returns a render pipeline descriptor for the renderer.
    ///
    /// This method loads the default Metal shader library from the module bundle and creates
    /// a descriptor with the vertex and fragment shader functions. The descriptor is configured
    /// for the specified color pixel format.
    ///
    /// - Parameter colorPixelFormat: The pixel format of the render target's color
    ///   attachment (typically the `MTKView`'s `colorPixelFormat`).
    /// - Returns: A configured `MTLRenderPipelineDescriptor` ready to create a
    ///   render pipeline state.
    /// - Throws: ``RendererError`` if shader functions cannot be found, or an error
    ///   from `MTLDevice.makeDefaultLibrary(bundle:)` if the library cannot be loaded.
    private func configureRenderPipeline(colorPixelFormat: MTLPixelFormat) throws -> MTLRenderPipelineDescriptor {
        // Load the app's default Metal shader library (contains vertex/fragment functions).
        let library = try device.makeDefaultLibrary(bundle: .module)
        guard let vertexFunction = library.makeFunction(name: "vertexShader") else {
            throw RendererError.missingVertexFunction(name: "vertexShader")
        }
        guard let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            throw RendererError.missingFragmentFunction(name: "fragmentShader")
        }
        // Create a pipeline descriptor that describes how the GPU should render.
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        return renderPipelineDescriptor
    }
}
