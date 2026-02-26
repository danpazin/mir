// Map.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2025 Daniil Pazin. All rights reserved.
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
    
    public init() {}
    
    public var body: some View {
        MapMetalKitView()
    }
}

#Preview {
    Map()
}
