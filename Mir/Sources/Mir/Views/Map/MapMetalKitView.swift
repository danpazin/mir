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
        let view = MTKView()
        view.device = context.coordinator.device
        view.delegate = context.coordinator
        return view
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
        let view = MTKView()
        view.device = context.coordinator.device
        view.delegate = context.coordinator
        return view
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
