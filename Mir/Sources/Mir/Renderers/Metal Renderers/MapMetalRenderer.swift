// MapMetalRenderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

final class MapMetalRenderer: Renderer {
    
    // MARK: - Properties
    
    /// The Metal device used to create and manage GPU resources.
    private let device: MTLDevice
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    private let commandQueue: MTLCommandQueue?
    /// The render pipeline state used to encode draw calls.
    private var renderPipelineState: MTLRenderPipelineState?
    // Temp
    private let mesh: MTKMesh!
    
    // MARK: - Initializers
    
    init(device: MTLDevice) {
        self.device = device
        commandQueue = device.makeCommandQueue()
        
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
    }
    
    // MARK: - Renderer
    
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
        renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
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
        renderPipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor) // temp
        return renderPipelineDescriptor
    }
    
    func renderFrame(to view: MTKView) {
        guard
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
            let renderPipelineState
        else {
            return
        }
        // Configure the encoder with the renderer's main pipeline state.
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0) // temp
        let submesh = mesh.submeshes.first! // temp
        // Draw the triangle
        renderEncoder.drawIndexedPrimitives(
            type: .triangle,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: 0
        ) // temp
        // Finalize the render pass
        renderEncoder.endEncoding()
        /// A drawable from the view that the method renders the frame to.
        let drawable = view.currentDrawable
        guard let drawable else { return }
        // Instruct the drawable to show itself on the device's display when the render pass completes.
        commandBuffer.present(drawable)
        // Submit the command buffer to the GPU
        commandBuffer.commit()
    }
}
