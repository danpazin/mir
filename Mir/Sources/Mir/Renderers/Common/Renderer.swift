// Renderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

@MainActor
protocol Renderer: AnyObject {

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
}
