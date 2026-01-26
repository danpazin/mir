// Renderer.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

@MainActor
protocol Renderer: AnyObject {

    /// Creates a new renderer instance configured for the specified Metal view.
    ///
    /// - Parameter view: The Metal view that provides:
    ///   - The Metal device used for rendering
    ///   - Drawable properties like pixel format and sample count
    ///   - The initial drawable size
    ///
    /// - Throws: An error if renderer initialization fails, such as:
    ///   - Missing or incompatible Metal device
    ///   - Failed resource creation (pipeline states, buffers, etc.)
    init(view: MTKView) throws
    
    /// Instructs the renderer to draw a frame for a view.
    ///
    /// - Parameter view: A view the renderer draws to, which provides:
    ///   - A render pass descriptor that reflects the view's current configuration.
    ///   - A drawable instance that the renderer presents to the screen.
    func renderFrame(to view: MTKView)
}
