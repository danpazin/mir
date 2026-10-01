// GeometryTests.swift
// MirTests
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Mir
import simd
import Testing

/// Checks the globe mesh: how many triangles it has, where its vertices sit and which way it faces.
@Suite("Globe geometry")
struct GeometryTests {

    @Test("Each subdivision level multiplies the triangle count by four", arguments: 0...5)
    func triangleCount(level: Int) {
        let globe = Globe(subdivisionLevel: level)
        #expect(globe.patches.count == 20 << (2 * level))
        #expect(globe.patches.allSatisfy { Int($0.level) == level })
    }

    @Test("Every vertex lies on the unit sphere", arguments: [0, 3])
    func verticesAreOnUnitSphere(level: Int) {
        for patch in Globe(subdivisionLevel: level).patches {
            for i in patch.vertices.indices {
                #expect(abs(simd_length(patch.vertices[i]) - 1) < 1e-5)
            }
        }
    }

    /// Back-face culling only keeps triangles that wind counter-clockwise seen from outside,
    /// so a single flipped triangle would leave a hole in the globe.
    @Test("Every triangle winds counter-clockwise seen from outside", arguments: [0, 3])
    func trianglesFaceOutward(level: Int) {
        for patch in Globe(subdivisionLevel: level).patches {
            let a = patch.vertices[0]
            let b = patch.vertices[1]
            let c = patch.vertices[2]
            let normal = simd_cross(b - a, c - a)
            #expect(simd_dot(normal, a + b + c) > 0)
        }
    }
}
