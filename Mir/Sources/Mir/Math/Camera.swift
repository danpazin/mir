// Camera.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import CoreFoundation
import simd

/// A virtual camera that defines the point of view for rendering the globe.
struct Camera {
    var viewMatrix: double4x4 { matrix_identity_double4x4 }
    
    func projectionMatrix(drawableSize: CGSize) -> double4x4 {
        let width = drawableSize.width
        let height = drawableSize.height
        if width > height {
            return double4x4(
                diagonal: SIMD4<Double>(x: height / width, y: 1.0, z: 1.0, w: 1.0)
            )
        } else if width < height {
            return double4x4(
                diagonal: SIMD4<Double>(x: 1.0, y: width / height, z: 1.0, w: 1.0)
            )
        } else {
            return double4x4(
                diagonal: SIMD4<Double>(repeating: 1.0)
            )
        }
    }
}
