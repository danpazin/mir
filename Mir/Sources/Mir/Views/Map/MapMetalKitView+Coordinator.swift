// MapMetalKitView+Coordinator.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
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
        private(set) var error: MapError?

        // MARK: - Initializers

        override init() {
            super.init()
            setUpDevice()
            setUpRenderer()
        }

        // MARK: - Setting Up

        /// Sets up the Metal device.
        private func setUpDevice() {
            guard let device = MTLCreateSystemDefaultDevice() else {
                error = MapError(kind: .deviceUnavailable)
                return
            }
            self.device = device
        }

        /// Sets up the renderer based on the device's capabilities.
        private func setUpRenderer() {
            guard let device else { return }
            if device.supportsFamily(.metal4) {
                setUpMetal4Renderer(with: device)
            } else {
                setUpMetalRenderer(with: device)
            }
        }

        private func setUpMetal4Renderer(with device: MTLDevice) {
            do {
                renderer = try MapMetal4Renderer(device: device)
            } catch {
                self.error = MapError(kind: .rendererUnavailable, underlyingError: error)
            }
        }

        private func setUpMetalRenderer(with device: MTLDevice) {
            renderer = MapMetalRenderer(device: device)
        }

        // MARK: - MTKViewDelegate

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            renderer?.scene.camera.aspectRatio = Float(size.width / size.height)
        }

        /// A delegate method called for each frame to be rendered.
        ///
        /// This method is part of the `MTKViewDelegate` protocol and is called
        /// on every frame to draw the content of the view. It delegates the
        /// rendering process to the `renderer`.
        ///
        /// - Parameter view: The `MTKView` to draw in.
        func draw(in view: MTKView) {
            renderer?.renderFrame(to: view)
        }
    }
}
