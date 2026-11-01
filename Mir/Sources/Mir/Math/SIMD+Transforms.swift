// SIMD+Transforms.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

extension double4x4 {
    
    /// A matrix that moves every point by `offset`.
    static func translation(_ offset: SIMD3<Double>) -> double4x4 {
        var matrix = matrix_identity_double4x4
        matrix.columns.3 = SIMD4<Double>(offset, 1.0)
        return matrix
    }
    
    /// A matrix that multiplies each coordinate by its own factor.
    static func scale(_ factor: SIMD3<Double>) -> double4x4 {
        double4x4(diagonal: SIMD4<Double>(factor, 1.0))
    }
    
    /// A matrix that maps distances from `near` to `far` in front of the camera, which looks along -z, into the GPU's depth range, 0 to 1.
    static func depthRange(near: Double, far: Double) -> double4x4 {
        let range = far - near
        return scale(SIMD3<Double>(x: 1.0, y: 1.0, z: 1.0 / -range)) * translation(SIMD3<Double>(x: 0.0, y: 0.0, z: near))
    }
}
