// CameraTests.swift
// MirTests
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import CoreLocation
import Mir
import simd
import Testing

/// Checks the camera's matrices: where the target lands on screen, how zoom moves the camera
/// and how depth is mapped.
@Suite("Camera")
struct CameraTests {

    /// Projects a world-space point to normalized device coordinates.
    private func project(_ point: SIMD3<Double>, with camera: Camera) -> SIMD3<Double> {
        let clip = camera.projectionMatrix * camera.viewMatrix * SIMD4(point, 1)
        return SIMD3(clip.x, clip.y, clip.z) / clip.w
    }

    @Test(
        "The point the camera looks at lands in the centre of the screen",
        arguments: [(0.0, 0.0), (45, 90), (-30, -120), (60, 179)]
    )
    func targetIsCentred(latitude: Double, longitude: Double) {
        var camera = Scene().camera
        camera.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let ndc = project(camera.target, with: camera)
        #expect(abs(ndc.x) < 1e-9 && abs(ndc.y) < 1e-9, "The target lands at \(ndc.x), \(ndc.y)")
    }

    @Test("Each zoom level halves the camera's altitude", arguments: [-1.0, -0.25, 0, 2])
    func zoomHalvesAltitude(zoom: Double) {
        var camera = Scene().camera
        camera.zoom = zoom
        let altitude = simd_length(camera.position) - 1
        camera.zoom = zoom + 1
        let closerAltitude = simd_length(camera.position) - 1
        #expect(abs(altitude / closerAltitude - 2) < 1e-9)
    }

    @Test("Depth maps the near plane to 0 and the far plane to 1")
    func depthRange() {
        let camera = Scene().camera
        let forward = simd_normalize(camera.target - camera.position)
        let near = project(camera.position + forward * camera.near, with: camera)
        let far = project(camera.position + forward * camera.far, with: camera)
        #expect(abs(near.z) < 1e-9)
        #expect(abs(far.z - 1) < 1e-9)
    }

    /// At the poles the view direction is almost parallel to the camera's fixed up vector
    /// (0, 1, 0). cos(90°) rounds to about 6e-17 rather than 0, so the cross product that builds
    /// the camera's sideways axis stays tiny but non-zero, and normalizing it is still finite.
    /// This guards that: a NaN matrix draws a blank frame, which would also benchmark as "faster".
    @Test("The view matrix stays finite at the poles", arguments: [90.0, -90.0])
    func viewMatrixAtPoles(latitude: Double) {
        var camera = Scene().camera
        camera.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: 0)
        let columns = camera.viewMatrix.columns
        let isFinite = [columns.0, columns.1, columns.2, columns.3].allSatisfy { column in
            column.x.isFinite && column.y.isFinite && column.z.isFinite && column.w.isFinite
        }
        #expect(isFinite)
    }
}
