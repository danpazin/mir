// MapMetalKitView+Coordinator.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2025 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetalKitView {

    /// A coordinator that bridges SwiftUI's `MapMetalKitView` with MetalKit view's delegate `MTKViewDelegate`.
    @MainActor
    final class Coordinator: NSObject, MTKViewDelegate {

        // MARK: - Properties

        /// The Metal device used for rendering.
        var device: MTLDevice?

        /// The renderer responsible for drawing the map.
        var renderer: (any Renderer)?

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            renderer?.renderFrame(to: view)
        }
    }
}
