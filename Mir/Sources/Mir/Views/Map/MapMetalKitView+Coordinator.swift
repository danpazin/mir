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

        /// The GPU, or nil if Metal isn't available.
        private(set) var device: MTLDevice?
        /// The renderer that draws each frame, or nil if it couldn't be created.
        private(set) var renderer: (any Renderer)?
        /// An error that occurred during setup, if any.
        private(set) var error: MapError?

        // MARK: - Initializers

        /// Creates a coordinator and sets up the GPU and the renderer, recording an error if either fails.
        override init() {
            super.init()
            setUpDevice()
            setUpRenderer()
        }

        // MARK: - Setting Up

        /// Gets the system's default GPU.
        private func setUpDevice() {
            guard let device = MTLCreateSystemDefaultDevice() else {
                error = MapError(kind: .deviceUnavailable)
                return
            }
            self.device = device
        }

        /// Creates the Metal 4 renderer where the GPU supports it, and the classic renderer otherwise.
        private func setUpRenderer() {
            guard let device else { return }
            #if targetEnvironment(simulator)
            // The simulators have no Metal 4, so they always use the classic renderer.
            setUpMetalRenderer(with: device)
            #else
            if device.supportsFamily(.metal4) {
                setUpMetal4Renderer(with: device)
            } else {
                setUpMetalRenderer(with: device)
            }
            #endif
        }

        #if !targetEnvironment(simulator)
        /// Creates the Metal 4 renderer, recording an error if that fails.
        private func setUpMetal4Renderer(with device: MTLDevice) {
            do {
                renderer = try MapMetal4Renderer(device: device)
            } catch {
                self.error = MapError(kind: .rendererUnavailable, underlyingError: error)
            }
        }
        #endif

        /// Creates the classic Metal renderer.
        private func setUpMetalRenderer(with device: MTLDevice) {
            renderer = MapMetalRenderer(device: device)
        }

        // MARK: - MTKViewDelegate

        /// Does nothing, because the projection reads the drawable size again every frame.
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        /// Draws one frame of the map.
        func draw(in view: MTKView) {
            renderer?.renderFrame(to: view)
        }
    }
}
