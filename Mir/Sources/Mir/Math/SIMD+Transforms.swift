// SIMD+Transforms.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

extension double4x4 {
    
    /// A matrix that turns z around: it takes the camera's right-handed space, where it looks along -z, into the GPU's left-handed one, where distance grows along +z.
    static func rightToLeftHanded() -> double4x4 {
        double4x4(
            diagonal: SIMD4<Double>(x: 1.0, y: 1.0, z: -1.0, w: 1.0)
        )
    }
    
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
    
    /// A matrix that makes far things smaller: it copies each point's distance, its z, into w, which the GPU divides by, so depth runs from 0 at `near` toward 1 at infinity.
    ///
    /// Each column is what one input coordinate adds to the output: column 2 is the point's z, column 3 is its 1.
    static func perspective() -> double4x4 {
        var matrix = matrix_identity_double4x4
        matrix.columns.2 = SIMD4<Double>(x: 0.0, y: 0.0, z: 1.0, w: 1.0)
        matrix.columns.3 = SIMD4<Double>(x: 0.0, y: 0.0, z: 0.0, w: 0.0)
        return matrix
    }
}
