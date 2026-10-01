// Globe.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

/// The 3D globe model, built from a base icosahedron subdivided by LOD.
package struct Globe {

    /// The subdivision level a new globe uses unless told otherwise: 5,120 triangles.
    package static let defaultSubdivisionLevel = 4

    // MARK: - Properties

    /// How many times each of the 20 root icosahedron patches was split into four.
    package let subdivisionLevel: Int
    /// The patches that cover the surface: 20 × 4^``subdivisionLevel`` triangles.
    package let patches: [GlobePatch]

    // MARK: - Initializers

    /// Makes a globe by repeatedly subdividing the root icosahedron patches.
    ///
    /// - Parameter subdivisionLevel: How many times to split each patch into four. Level 0 is the
    ///   bare icosahedron, which looks faceted; each level multiplies the triangle count by 4.
    package init(subdivisionLevel: Int = Globe.defaultSubdivisionLevel) {
        precondition(subdivisionLevel >= 0, "The subdivision level can't be negative")
        let roots = Icosahedron.makePatches()
        var patches: [GlobePatch] = []
        patches.reserveCapacity(roots.count)
        for i in roots.indices {
            patches.append(roots[i])
        }
        for _ in 0..<subdivisionLevel {
            var children: [GlobePatch] = []
            children.reserveCapacity(patches.count * 4)
            for patch in patches {
                let quarters = patch.subdivided()
                for i in quarters.indices {
                    children.append(quarters[i])
                }
            }
            patches = children
        }
        self.subdivisionLevel = subdivisionLevel
        self.patches = patches
    }
}
