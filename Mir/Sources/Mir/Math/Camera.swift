// Camera.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import CoreLocation
import simd
import SwiftUI

/// A virtual camera that defines the point of view for rendering the globe.
struct Camera {

    private let globeRadius: Double = 1.0

    // MARK: - Position

    var position: SIMD3<Double> {
        let referenceAltitude = globeRadius / sin(fov.radians * 0.5) - globeRadius
        let altitude = referenceAltitude / pow(2, zoom)
        return target * (globeRadius + altitude)
    }
    /// Camera rotation.
    var bearing: Angle
    /// Camera tilt angle.
    var pitch: Double

    // MARK: - Orientation

    /// The point in world space the camera is looking at.
    var target: SIMD3<Double> {
        let latitude = coordinate.latitude * .pi / 180.0
        let longitude = coordinate.longitude * .pi / 180.0
        let x = cos(latitude) * cos(longitude)
        let y = sin(latitude)
        let z = cos(latitude) * sin(longitude)
        return SIMD3(x, y, z)
    }
    /// The world-space direction that the camera considers "up".
    var up: SIMD3<Double> { SIMD3(0, 1, 0) }
    /// Location on Earth.
    var coordinate: CLLocationCoordinate2D

    // MARK: - Lens

    /// The vertical field of view.
    var fov: Angle
    /// The distance to the near clipping plane, in world units.
    var near: Double
    /// The distance to the far clipping plane, in world units.
    var far: Double
    /// The distance of the map from the viewer.
    var zoom: Double

    // MARK: - Viewport

    var aspectRatio: Double

    // MARK: - Matrices

    var viewMatrix: double4x4 {
        let z = normalize(position - target)
        let x = normalize(cross(up, z))
        let y = cross(z, x)
        return double4x4(columns: (
            SIMD4(x.x, y.x, z.x, 0),
            SIMD4(x.y, y.y, z.y, 0),
            SIMD4(x.z, y.z, z.z, 0),
            SIMD4(-(dot(x, position)), -dot(y, position), -dot(z, position), 1)
        ))
    }

    var projectionMatrix: double4x4 {
        let y = 1 / tan(fov.radians * 0.5)
        let x = y / aspectRatio
        let z = far / (near - far)
        let w = (near * far) / (near - far)
        return double4x4(columns: (
            SIMD4(x, 0, 0, 0),
            SIMD4(0, y, 0, 0),
            SIMD4(0, 0, z, -1),
            SIMD4(0, 0, w, 0)
        ))
    }
}
