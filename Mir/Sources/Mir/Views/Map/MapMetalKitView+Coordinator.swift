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
        private(set) var device: MTLDevice?

        /// The renderer responsible for drawing the map.
        private(set) var renderer: (any Renderer)?

        /// An error that occurred during setup, if any.
        private(set) var error: Error?

        // MARK: - Initializers

        override init() {
            super.init()
            setUpDevice()
            setUpRenderer()
        }

        // MARK: - Create Resources

        private func setUpDevice() {
            guard let device = MTLCreateSystemDefaultDevice() else {
                error = MapError(kind: .deviceUnavailable)
                return
            }
            self.device = device
        }

        private func setUpRenderer() {
            guard let device else { return }
            if device.supportsFamily(.metal4) {
                renderer = MapMetal4Renderer(device: device)
            } else {
                renderer = MapMetalRenderer(device: device)
            }
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            renderer?.renderFrame(to: view)
        }
    }
}
