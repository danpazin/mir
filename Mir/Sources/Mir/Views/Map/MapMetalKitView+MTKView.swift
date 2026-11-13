// MapMetalKitView+MTKView.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetalKitView {

    /// Makes the Metal view that draws the map, or a view that explains why the map can't be drawn.
    static func makeMTKView(coordinator: Coordinator) -> MTKView {
        guard let device = coordinator.device else {
            let error = coordinator.error ?? MapError(kind: .deviceUnavailable)
            let description = error.localizedDescription
            let view = Self.makeErrorMTKView(message: description)
            return view
        }
        guard let renderer = coordinator.renderer else {
            let error = coordinator.error ?? MapError(kind: .rendererUnavailable)
            let description = error.localizedDescription
            let view = Self.makeErrorMTKView(message: description)
            return view
        }
        let view = MTKView()
        view.device = device
        view.delegate = coordinator
        do {
            try renderer.compileRenderPipeline(colorPixelFormat: view.colorPixelFormat)
            return view
        } catch let error as LocalizedError {
            let description = error.errorDescription ?? "Failed to set up map rendering: \(error.localizedDescription)"
            let view = Self.makeErrorMTKView(message: description)
            return view
        } catch {
            let description = "Failed to set up map rendering: \(error.localizedDescription)"
            let view = Self.makeErrorMTKView(message: description)
            return view
        }
    }
}
