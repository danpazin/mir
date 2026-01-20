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
    
    // MARK: Creating and updating the view
    
    func makeUIView(context: Context) -> some UIView {
        let coordinator = context.coordinator
        guard let device = coordinator.device else {
            let error = MapError(kind: .deviceUnavailable)
            let description = error.errorDescription ?? "Metal is not available on this device."
            let view = Self.makeErrorMTKView(message: description)
            return view
        }
        guard let renderer = coordinator.renderer else {
            let error = MapError(kind: .rendererUnavailable)
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
    
    // MARK: Providing a custom coordinator object
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        let device = MTLCreateSystemDefaultDevice()
        coordinator.device = device
        guard let device else { return coordinator }
        if device.supportsFamily(.metal4) {
            coordinator.renderer = MapMetal4Renderer(device: device)
        } else {
            coordinator.renderer = MapMetalRenderer(device: device)
        }
        return coordinator
    }
}
#elseif canImport(AppKit)
struct MapMetalKitView: NSViewRepresentable {
    
    // MARK: - NSViewRepresentable
    
    // MARK: Creating and updating the view
    
    func makeNSView(context: Context) -> some NSView {
        let coordinator = context.coordinator
        guard let device = coordinator.device else {
            let error = MapError(kind: .deviceUnavailable)
            let description = error.errorDescription ?? "Metal is not available on this device."
            let view = Self.makeErrorMTKView(message: description)
            return view
        }
        guard let renderer = coordinator.renderer else {
            let error = MapError(kind: .rendererUnavailable)
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
    
    // MARK: Providing a custom coordinator object
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        let device = MTLCreateSystemDefaultDevice()
        coordinator.device = device
        guard let device else { return coordinator }
        if device.supportsFamily(.metal4) {
            coordinator.renderer = MapMetal4Renderer(device: device)
        } else {
            coordinator.renderer = MapMetalRenderer(device: device)
        }
        return coordinator
    }
}
#endif
