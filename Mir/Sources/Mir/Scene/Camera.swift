// Camera.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import CoreFoundation
import CoreLocation
import Spatial
import simd

/// A virtual camera that defines the point of view for rendering.
struct Camera {
    
    // MARK: - Matrices
    
    /// Moves the world the opposite way to the camera, because the GPU always looks from the same spot.
    var viewMatrix: double4x4 {
        // The longitude turn runs first, and is negated to bring an eastern coordinate to the front.
        .translation(SIMD3<Double>(x: 0.0, y: 0.0, z: -distance))
        * .rotationAroundX(Angle2D(degrees: coordinate.latitude))
        * .rotationAroundY(Angle2D(degrees: -coordinate.longitude))
    }
    
    /// Turns z around for the GPU, makes far things smaller, magnifies them through the lens, and squeezes the longer side of the view so nothing looks stretched.
    func projectionMatrix(drawableSize: CGSize) -> double4x4 {
        .scale(aspectCorrection(for: drawableSize) * lensMagnification) * .perspective() * .rightToLeftHanded()
    }
    
    // MARK: - Placement
    
    /// The latitude and longitude the camera looks from, toward the world's centre, in degrees, with north and east positive.
    var coordinate: CLLocationCoordinate2D
    
    /// How far the camera is from the world's centre, in world units.
    var distance: Double
    
    // MARK: - Lens
    
    /// The lens on the camera, which sets how wide it sees.
    private let lens = Lens()
    
    /// The factors that make things look bigger through the lens, across and down, with depth left as it is.
    private var lensMagnification: SIMD3<Double> {
        SIMD3<Double>(x: lens.magnification, y: lens.magnification, z: 1.0)
    }
    
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
