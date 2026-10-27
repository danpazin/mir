// SIMD+Conversion.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

extension simd_float4x4 {

    /// Creates a single-precision matrix by downcasting each column of a double-precision matrix.
    ///
    /// This is the CPU→GPU precision bridge: precision-sensitive math (camera, geographic
    /// transforms) runs in `double4x4` on the CPU, then downcasts to `simd_float4x4` at the
    /// point of uploading to a shader, which expects `float`.
    ///
    /// - Parameter m: A double-precision 4×4 matrix.
    init(_ m: double4x4) {
        self.init(columns: (
            simd_float4(m.columns.0),
            simd_float4(m.columns.1),
            simd_float4(m.columns.2),
            simd_float4(m.columns.3)
        ))
    }
}
