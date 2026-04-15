// Camera.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

/// A virtual camera that defines the point of view for rendering the globe.
struct Camera {

    // MARK: - Position

    var position: SIMD3<Float>

    // MARK: - Orientation

    /// The point in world space the camera is looking at.
    var target: SIMD3<Float>
    /// The world-space direction that the camera considers "up".
    var up: SIMD3<Float>

    // MARK: - Lens

    /// The vertical field of view, in radians.
    var fov: Float
    /// The distance to the near clipping plane, in world units.
    var near: Float
    /// The distance to the far clipping plane, in world units.
    var far: Float

    // MARK: - Viewport

    var aspectRatio: Float

    // MARK: - Matrices

    var viewMatrix: float4x4 {
        let z = normalize(position - target)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        return float4x4(columns: (
            SIMD4(x.x, y.x, z.x, 0),
            SIMD4(x.y, y.y, z.y, 0),
            SIMD4(x.z, y.z, z.z, 0),
            SIMD4(-(dot(x, position)), -dot(y, position), -dot(z, position), 1)
        ))
    }

    var projectionMatrix: float4x4 {
        let y = 1 / tan(fov * 0.5)
        let x = y / aspectRatio
        let z = far / (near - far)
        let w = (near * far) / (near - far)
        return float4x4(columns: (
            SIMD4(x, 0, 0, 0),
            SIMD4(0, y, 0, 0),
            SIMD4(0, 0, z, -1),
            SIMD4(0, 0, w, 0)
        ))
    }
}
