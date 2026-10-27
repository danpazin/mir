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
}
