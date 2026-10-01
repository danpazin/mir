// GlobePatch.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

/// A triangular piece of the globe surface used as a node in the LOD quadtree.
package struct GlobePatch {

    // MARK: - Properties

    /// The three corner positions on the unit sphere.
    package let vertices: InlineArray<3, SIMD3<Float>>
    /// The vertex indices that define the triangle winding order.
    package let indices: [UInt16]
    /// The subdivision depth (0 for root icosahedron patches).
    package let level: UInt8

    // MARK: - Subdividing

    /// Splits the patch into four children one level deeper.
    ///
    /// The midpoint of each edge is pushed out onto the unit sphere, so the surface gets rounder
    /// with every level. The children keep the parent's counter-clockwise winding, so back-face
    /// culling keeps working.
    package func subdivided() -> InlineArray<4, GlobePatch> {
        let a = vertices[0]
        let b = vertices[1]
        let c = vertices[2]
        let ab = simd_normalize((a + b) * 0.5)
        let bc = simd_normalize((b + c) * 0.5)
        let ca = simd_normalize((c + a) * 0.5)
        let level = level + 1
        return [
            GlobePatch(vertices: [a, ab, ca], indices: indices, level: level),
            GlobePatch(vertices: [ab, b, bc], indices: indices, level: level),
            GlobePatch(vertices: [ca, bc, c], indices: indices, level: level),
            GlobePatch(vertices: [ab, bc, ca], indices: indices, level: level)
        ]
    }
}
