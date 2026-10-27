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

        private(set) var device: MTLDevice?
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

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            renderer?.renderFrame(to: view)
        }
    }
}
