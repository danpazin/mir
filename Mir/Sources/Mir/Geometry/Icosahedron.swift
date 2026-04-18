// Icosahedron.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

enum Icosahedron {

    // MARK: - Methods

    static func makePatches() -> InlineArray<20, GlobePatch> {
        let ϕ: Float = (1 + Float(5).squareRoot()) * 0.5
        let vertices: InlineArray<12, SIMD3<Float>> = [
            simd_normalize([-1,  ϕ,  0]), simd_normalize([ 1,  ϕ,  0]), simd_normalize([-1, -ϕ,  0]), simd_normalize([ 1, -ϕ,  0]),
            simd_normalize([ 0, -1,  ϕ]), simd_normalize([ 0,  1,  ϕ]), simd_normalize([ 0, -1, -ϕ]), simd_normalize([ 0,  1, -ϕ]),
            simd_normalize([ ϕ,  0, -1]), simd_normalize([ ϕ,  0,  1]), simd_normalize([-ϕ,  0, -1]), simd_normalize([-ϕ,  0,  1])
        ]
        let patches: InlineArray<20, GlobePatch> = [
            GlobePatch(vertices: [vertices[0], vertices[11], vertices[5]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[0], vertices[5], vertices[1]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[0], vertices[1], vertices[7]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[0], vertices[7], vertices[10]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[0], vertices[10], vertices[11]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[1], vertices[5], vertices[9]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[5], vertices[11], vertices[4]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[11], vertices[10], vertices[2]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[10], vertices[7], vertices[6]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[7], vertices[1], vertices[8]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[3], vertices[9], vertices[4]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[3], vertices[4], vertices[2]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[3], vertices[2], vertices[6]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[3], vertices[6], vertices[8]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[3], vertices[8], vertices[9]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[4], vertices[9], vertices[5]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[2], vertices[4], vertices[11]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[6], vertices[2], vertices[10]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[8], vertices[6], vertices[7]], indices: [0, 1, 2], level: 0),
            GlobePatch(vertices: [vertices[9], vertices[8], vertices[1]], indices: [0, 1, 2], level: 0)
        ]
        return patches
    }
}
