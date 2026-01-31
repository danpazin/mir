// MapMetalKitView.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2025 Daniil Pazin. All rights reserved.
//

import SwiftUI
import MetalKit

#if canImport(UIKit)
struct MapMetalKitView: UIViewRepresentable {

    // MARK: - UIViewRepresentable

    // MARK: Creating and Updating the View

    func makeUIView(context: Context) -> some UIView {
        let coordinator = context.coordinator
        guard let device = coordinator.device else {
            let error = coordinator.error ?? MapError(kind: .deviceUnavailable)
            let description = error.errorDescription ?? "Metal is not available on this device."
            let view = Self.makeErrorMTKView(message: description)
            return view
        }
        guard let renderer = coordinator.renderer else {
            let error = coordinator.error ?? MapError(kind: .rendererUnavailable)
            let description = error.errorDescription ?? "The renderer could not be created."
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

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    // MARK: Providing a Custom Coordinator Object

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
}
#elseif canImport(AppKit)
struct MapMetalKitView: NSViewRepresentable {

    // MARK: - NSViewRepresentable

    // MARK: Creating and Updating the View

    func makeNSView(context: Context) -> some NSView {
        let coordinator = context.coordinator
        guard let device = coordinator.device else {
            let error = coordinator.error ?? MapError(kind: .deviceUnavailable)
            let description = error.errorDescription ?? "Metal is not available on this device."
            let view = Self.makeErrorMTKView(message: description)
            return view
        }
        guard let renderer = coordinator.renderer else {
            let error = coordinator.error ?? MapError(kind: .rendererUnavailable)
            let description = error.errorDescription ?? "The renderer could not be created."
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

    func updateNSView(_ nsView: NSViewType, context: Context) {}

    // MARK: Providing a Custom Coordinator Object

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        return coordinator
    }
}
#endif
