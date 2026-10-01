// MapMetal4Renderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

// The Simulator SDK doesn't include Metal 4, so this renderer only builds for devices and Macs.
#if !targetEnvironment(simulator)

import MetalKit
import MirSharedTypes

package final class MapMetal4Renderer: Renderer {

    // MARK: - Properties

    /// The Metal device used to create and manage GPU resources.
    package let device: MTLDevice
    /// The command queue responsible for scheduling and submitting command buffers to the GPU.
    let commandQueue: (any MTL4CommandQueue)?
    /// The render pipeline state used to encode draw calls.
    package var renderPipelineState: MTLRenderPipelineState?
    /// A residency set that keeps resources in memory for the app's lifetime.
    var residencySet: MTLResidencySet?
    /// A shared buffer that holds the per-frame uniform data (matrices) for the vertex shader.
    let uniformBuffer: MTLBuffer?
    /// A shared buffer that holds the vertex data for all globe patches, structured as a flat array of float3 positions.
    let globeBuffer: MTLBuffer?
    /// The scene that holds the camera and objects to render.
    package var scene: Scene
    /// The work the most recently encoded frame asked of the GPU.
    package private(set) var lastFrameStatistics = FrameStatistics()
    /// The current Metal 4 command buffer used to encode and submit GPU work for a frame.
    private let commandBuffer: MTL4CommandBuffer?
    /// An object that stores commands for each frame while the app encodes them and the GPU runs them.
    private let commandAllocator: MTL4CommandAllocator?
    /// An argument table that stores the resource bindings for a render encoder.
    private var argumentTable: MTL4ArgumentTable?
    /// The offscreen texture currently in the residency set.
    private var offscreenTexture: MTLTexture?
    /// The residency set of the view's layer, which keeps its drawables resident.
    private var drawableResidencySet: MTLResidencySet?
    /// The subdivision level of the globe whose vertices are in ``globeBuffer``, if any.
    private var uploadedSubdivisionLevel: Int?

    // MARK: - Initializers

    /// Makes a renderer whose vertex buffer fits the scene's globe.
    package init(device: MTLDevice, scene: Scene = Scene()) throws {
        self.device = device
        self.scene = scene
        commandQueue = device.makeMTL4CommandQueue()
        commandBuffer = device.makeCommandBuffer()
        commandAllocator = device.makeCommandAllocator()
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
        globeBuffer = device.makeBuffer(length: MemoryLayout<InlineArray<3, SIMD3<Float>>>.stride * scene.globe.patches.count)
        argumentTable = try makeArgumentTable()
        residencySet = try makeResidencySet()
        setUpResidency()
    }

    // MARK: - Renderer

    package func renderFrame(to view: MTKView) {
        guard
            let commandQueue,
            let commandBuffer,
            let renderPassDescriptor = view.currentMTL4RenderPassDescriptor,
            let drawable = view.currentDrawable
        else {
            return
        }
        makeDrawablesResident(for: view)
        do {
            try encodeFrame(renderPassDescriptor: renderPassDescriptor)
        } catch {
            return
        }
        commandQueue.waitForDrawable(drawable)
        commandQueue.commit([commandBuffer])
        commandQueue.signalDrawable(drawable)
        drawable.present()
    }

    @discardableResult
    package func renderFrame(into texture: MTLTexture) throws -> FrameTiming {
        let clock = ContinuousClock()
        let start = clock.now
        guard let commandQueue, let commandBuffer else {
            throw RendererError.encodingUnavailable
        }
        makeResident(texture)
        let renderPassDescriptor = MTL4RenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        try encodeFrame(renderPassDescriptor: renderPassDescriptor)
        let encoded = clock.now
        let feedback = CommitFeedback()
        let options = MTL4CommitOptions()
        options.addFeedbackHandler { feedback.record($0) }
        commandQueue.commit([commandBuffer], options: options)
        guard let report = feedback.wait(timeoutSeconds: 5) else {
            throw RendererError.gpuTimeout
        }
        let finished = clock.now
        if let error = report.error {
            throw RendererError.gpuFailure(description: error)
        }
        return FrameTiming(
            encodeSeconds: (encoded - start).inSeconds,
            gpuSeconds: report.gpuSeconds,
            totalSeconds: (finished - start).inSeconds
        )
    }

    // MARK: - Encoding

    /// Encodes the scene's draw calls into the command buffer.
    ///
    /// Both ``renderFrame(to:)`` and ``renderFrame(into:)`` call this, so offscreen tests and
    /// benchmarks exercise exactly the work the view does.
    private func encodeFrame(renderPassDescriptor: MTL4RenderPassDescriptor) throws {
        guard
            let commandBuffer,
            let commandAllocator,
            let renderPipelineState,
            let argumentTable,
            let uniformBuffer,
            let globeBuffer
        else {
            throw RendererError.encodingUnavailable
        }
        commandAllocator.reset()
        commandBuffer.beginCommandBuffer(allocator: commandAllocator)
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            commandBuffer.endCommandBuffer()
            throw RendererError.encodingUnavailable
        }
        let signpost = Signposts.renderer.beginInterval("Encode frame")
        defer { Signposts.renderer.endInterval("Encode frame", signpost) }
        renderEncoder.setRenderPipelineState(renderPipelineState)
        // Globe triangles wind counter-clockwise seen from outside; Metal treats clockwise as front-facing by default.
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setCullMode(.back)
        let uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: simd_float4x4(scene.camera.viewMatrix),
            projectionMatrix: simd_float4x4(scene.camera.projectionMatrix)
        )
        uniformBuffer.contents().storeBytes(of: uniforms, as: Uniforms.self)
        let uploadedVertexBytes: Int
        do {
            uploadedVertexBytes = try uploadGlobeIfNeeded(into: globeBuffer)
        } catch {
            renderEncoder.endEncoding()
            commandBuffer.endCommandBuffer()
            throw error
        }
        let vertexCount = scene.globe.patches.count * 3
        argumentTable.setAddress(globeBuffer.gpuAddress, index: 0)
        argumentTable.setAddress(uniformBuffer.gpuAddress, index: 1)
        renderEncoder.setArgumentTable(argumentTable, stages: .vertex)
        renderEncoder.drawPrimitives(primitiveType: .triangle, vertexStart: 0, vertexCount: vertexCount)
        renderEncoder.endEncoding()
        commandBuffer.endCommandBuffer()
        var statistics = FrameStatistics()
        statistics.drawCalls = 1
        statistics.vertexCount = vertexCount
        statistics.uploadedBytes = MemoryLayout<Uniforms>.stride + uploadedVertexBytes
        lastFrameStatistics = statistics
    }

    /// Copies the globe's vertices into the vertex buffer, but only when the globe has changed.
    ///
    /// The globe's geometry depends only on its subdivision level, so after the first frame most
    /// frames upload nothing. Copying it every frame cost 0.87 ms of CPU time per frame at level 6.
    ///
    /// - Returns: The number of bytes copied for this frame.
    private func uploadGlobeIfNeeded(into globeBuffer: MTLBuffer) throws -> Int {
        guard uploadedSubdivisionLevel != scene.globe.subdivisionLevel else { return 0 }
        let vertexCount = scene.globe.patches.count * 3
        let byteCount = vertexCount * MemoryLayout<SIMD3<Float>>.stride
        guard byteCount <= globeBuffer.length else {
            throw RendererError.bufferTooSmall(needed: byteCount, available: globeBuffer.length)
        }
        // Flatten patch vertices into the contiguous float3 array `vertexShader` reads.
        let vertices = globeBuffer.contents().bindMemory(to: SIMD3<Float>.self, capacity: vertexCount)
        var index = 0
        for patch in scene.globe.patches {
            for corner in patch.vertices.indices {
                vertices[index] = patch.vertices[corner]
                index += 1
            }
        }
        uploadedSubdivisionLevel = scene.globe.subdivisionLevel
        return byteCount
    }

    // MARK: - Residency

    /// Adds the view's layer residency set to the command queue, replacing the previous view's set.
    ///
    /// Metal 4 only lets the GPU render into and present drawables whose resources are resident.
    /// The layer keeps its residency set up to date as it creates new drawables.
    private func makeDrawablesResident(for view: MTKView) {
        guard
            let commandQueue,
            let layerResidencySet = (view.layer as? CAMetalLayer)?.residencySet,
            layerResidencySet !== drawableResidencySet
        else {
            return
        }
        if let drawableResidencySet {
            commandQueue.removeResidencySet(drawableResidencySet)
        }
        commandQueue.addResidencySet(layerResidencySet)
        drawableResidencySet = layerResidencySet
    }

    /// Adds an offscreen texture to the residency set, replacing the previous one.
    ///
    /// Metal 4 only lets the GPU access resources in a residency set the queue knows about.
    private func makeResident(_ texture: MTLTexture) {
        guard let residencySet, offscreenTexture !== texture else { return }
        if let offscreenTexture {
            residencySet.removeAllocation(offscreenTexture)
        }
        residencySet.addAllocation(texture)
        residencySet.commit()
        offscreenTexture = texture
    }
}
#endif
