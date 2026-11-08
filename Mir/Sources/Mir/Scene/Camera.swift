// Camera.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import CoreFoundation
import simd

/// A virtual camera that defines the point of view for rendering.
struct Camera {
    
    // MARK: - Matrices
    
    /// Moves the world the opposite way to the camera, because the GPU always looks from the same spot.
    var viewMatrix: double4x4 {
        .translation(-position)
    }
    
    /// Turns z around for the GPU, makes far things smaller, and squeezes the longer side of the view so nothing looks stretched.
    func projectionMatrix(drawableSize: CGSize) -> double4x4 {
        .scale(aspectCorrection(for: drawableSize)) * .perspective() * .rightToLeftHanded()
    }
    
    // MARK: - Placement
    
    /// Where the camera is, in world units.
    private var position: SIMD3<Double> {
        SIMD3<Double>(x: 0.0, y: 0.0, z: 1.5)
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
