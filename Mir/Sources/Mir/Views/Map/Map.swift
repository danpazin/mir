// Map.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import SwiftUI

/// A view that displays an interactive map.
///
/// The following example displays a map:
///
/// ```swift
/// var body: some View {
///     Map()
/// }
/// ```
public struct Map: View {
    
    /// Creates a map.
    public init() {}
    
    /// The view that draws the map with Metal.
    public var body: some View {
        MapMetalKitView()
    }
}

#Preview {
    Map()
}
