// Renderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

@MainActor
package protocol Renderer: AnyObject {

    /// The scene that holds the camera and objects to render.
    var scene: Scene { get set }

    /// The work the most recently encoded frame asked of the GPU.
    var lastFrameStatistics: FrameStatistics { get }

    // MARK: - Create a Render Pipeline

    /// Compiles (or recompiles) the Metal render pipeline state the renderer needs to draw.
    ///
    /// - Parameter colorPixelFormat: The pixel format of the render target’s color attachment
    ///   (typically `MTKView.colorPixelFormat`).
    /// - Throws: A renderer-specific error if the pipeline can’t be created (for example, missing
    ///   shader functions, an invalid pipeline descriptor, or a Metal compilation failure).
    func compileRenderPipeline(colorPixelFormat: MTLPixelFormat) throws

    /// Instructs the renderer to draw a frame for a view.
    ///
    /// - Parameter view: A view the renderer draws to, which provides:
    ///   - A render pass descriptor that reflects the view's current configuration.
    ///   - A drawable instance that the renderer presents to the screen.
    func renderFrame(to view: MTKView)

    /// Draws a frame into a texture and waits for the GPU to finish it.
    ///
    /// Tests and benchmarks use this to render without a window. It encodes the same commands
    /// as ``renderFrame(to:)``, so what they check and measure is what the view shows.
    ///
    /// - Parameter texture: A render target texture, for example from ``OffscreenTarget``.
    /// - Returns: How long the frame took to encode, to run on the GPU and in total.
    /// - Throws: ``RendererError`` if the frame can’t be encoded or the GPU doesn’t finish it.
    @discardableResult
    func renderFrame(into texture: MTLTexture) throws -> FrameTiming
}
