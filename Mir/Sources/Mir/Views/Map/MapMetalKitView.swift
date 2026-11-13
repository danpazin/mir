// MapMetalKitView.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import SwiftUI
import MetalKit

#if canImport(UIKit)
/// A SwiftUI view that hosts the Metal view the map is drawn into.
struct MapMetalKitView: UIViewRepresentable {

    // MARK: - UIViewRepresentable

    // MARK: Creating and Updating the View

    /// Makes the Metal view that draws the map, or an error view if the map can't be drawn.
    func makeUIView(context: Context) -> some UIView {
        Self.makeMTKView(coordinator: context.coordinator)
    }

    /// Does nothing, because the map doesn't depend on any SwiftUI state yet.
    func updateUIView(_ uiView: UIViewType, context: Context) {}

    // MARK: Providing a Custom Coordinator Object

    /// Makes the coordinator that sets up Metal and draws each frame.
    func makeCoordinator() -> Coordinator {
        .init()
    }
}
#elseif canImport(AppKit)
/// A SwiftUI view that hosts the Metal view the map is drawn into.
struct MapMetalKitView: NSViewRepresentable {

    // MARK: - NSViewRepresentable

    // MARK: Creating and Updating the View

    /// Makes the Metal view that draws the map, or an error view if the map can't be drawn.
    func makeNSView(context: Context) -> some NSView {
        Self.makeMTKView(coordinator: context.coordinator)
    }

    /// Does nothing, because the map doesn't depend on any SwiftUI state yet.
    func updateNSView(_ nsView: NSViewType, context: Context) {}

    // MARK: Providing a Custom Coordinator Object

    /// Makes the coordinator that sets up Metal and draws each frame.
    func makeCoordinator() -> Coordinator {
        .init()
    }
}
#endif
