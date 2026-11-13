// MapMetalKitView.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import SwiftUI
import MetalKit

#if canImport(UIKit)
struct MapMetalKitView: UIViewRepresentable {

    // MARK: - UIViewRepresentable

    // MARK: Creating and Updating the View

    func makeUIView(context: Context) -> some UIView {
        Self.makeMTKView(coordinator: context.coordinator)
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    // MARK: Providing a Custom Coordinator Object

    func makeCoordinator() -> Coordinator {
        .init()
    }
}
#elseif canImport(AppKit)
struct MapMetalKitView: NSViewRepresentable {

    // MARK: - NSViewRepresentable

    // MARK: Creating and Updating the View

    func makeNSView(context: Context) -> some NSView {
        Self.makeMTKView(coordinator: context.coordinator)
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}

    // MARK: Providing a Custom Coordinator Object

    func makeCoordinator() -> Coordinator {
        .init()
    }
}
#endif
