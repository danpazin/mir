// GlobePatch.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

/// A triangular piece of the globe surface used as a node in the LOD quadtree.
struct GlobePatch {

    // MARK: - Properties

    /// The three corner positions on the unit sphere.
    let vertices: InlineArray<3, SIMD3<Float>>
    /// The vertex indices that define the triangle winding order.
    let indices: [UInt16]
    /// The subdivision depth (0 for root icosahedron patches).
    let level: UInt8
}
