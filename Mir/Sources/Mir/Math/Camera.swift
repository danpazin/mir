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
    
    // MARK: - Matrices
    
    /// Moves the world the opposite way to the camera, because the GPU always looks from the same spot.
    var viewMatrix: double4x4 {
        .translation(-position)
    }
    
    /// Squeezes the longer side of the view, so the globe stays round.
    func projectionMatrix(drawableSize: CGSize) -> double4x4 {
        .scale(aspectCorrection(for: drawableSize))
    }
    
    // MARK: - Placement
    
    /// Where the camera is, in world units.
    private var position: SIMD3<Double> {
        .zero
    }
    
    // MARK: - Lens
    
    /// The factors that make one unit cover the same number of pixels across and down.
    private func aspectCorrection(for size: CGSize) -> SIMD3<Double> {
        if size.width > size.height {
            return SIMD3<Double>(x: size.height / size.width, y: 1.0, z: 1.0)
        }
        if size.width < size.height {
            return SIMD3<Double>(x: 1.0, y: size.width / size.height, z: 1.0)
        }
        return .one
    }
}
