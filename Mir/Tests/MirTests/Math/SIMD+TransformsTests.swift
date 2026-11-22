// SIMD+TransformsTests.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Spatial
import Testing
import simd
@testable import Mir

/// Checks that the turns follow the right-hand rule.
struct SIMDTransformsTests {
    
    // MARK: - Properties
    
    /// How far apart two points may be and still count as the same, to allow for rounding.
    private let tolerance = 1.0e-9
    
    /// A quarter turn, which moves each axis onto the next one.
    private let quarterTurn = Angle2D(degrees: 90.0)
    
    // MARK: - Turning Around X
    
    /// Checks that a quarter turn around x carries +y to +z and +z to -y, and leaves +x where it is.
    @Test(arguments: [
        (SIMD4<Double>(x: 0.0, y: 1.0, z: 0.0, w: 1.0), SIMD4<Double>(x: 0.0, y: 0.0, z: 1.0, w: 1.0)),
        (SIMD4<Double>(x: 0.0, y: 0.0, z: 1.0, w: 1.0), SIMD4<Double>(x: 0.0, y: -1.0, z: 0.0, w: 1.0)),
        (SIMD4<Double>(x: 1.0, y: 0.0, z: 0.0, w: 1.0), SIMD4<Double>(x: 1.0, y: 0.0, z: 0.0, w: 1.0)),
    ])
    func rotationAroundX_quarterTurn_followsRightHandRule(point: SIMD4<Double>, expected: SIMD4<Double>) {
        let sut = double4x4.rotationAroundX(quarterTurn)
        #expect(simd_distance(sut * point, expected) < tolerance)
    }
    
    /// Checks that turning around x by no angle leaves every point where it is.
    @Test func rotationAroundX_zeroTurn_isIdentity() {
        let sut = double4x4.rotationAroundX(.zero)
        #expect(sut == matrix_identity_double4x4)
    }
    
    // MARK: - Turning Around Y
    
    /// Checks that a quarter turn around y carries +z to +x and +x to -z, and leaves +y where it is.
    @Test(arguments: [
        (SIMD4<Double>(x: 0.0, y: 0.0, z: 1.0, w: 1.0), SIMD4<Double>(x: 1.0, y: 0.0, z: 0.0, w: 1.0)),
        (SIMD4<Double>(x: 1.0, y: 0.0, z: 0.0, w: 1.0), SIMD4<Double>(x: 0.0, y: 0.0, z: -1.0, w: 1.0)),
        (SIMD4<Double>(x: 0.0, y: 1.0, z: 0.0, w: 1.0), SIMD4<Double>(x: 0.0, y: 1.0, z: 0.0, w: 1.0)),
    ])
    func rotationAroundY_quarterTurn_followsRightHandRule(point: SIMD4<Double>, expected: SIMD4<Double>) {
        let sut = double4x4.rotationAroundY(quarterTurn)
        #expect(simd_distance(sut * point, expected) < tolerance)
    }
    
    /// Checks that turning around y by no angle leaves every point where it is.
    @Test func rotationAroundY_zeroTurn_isIdentity() {
        let sut = double4x4.rotationAroundY(.zero)
        #expect(sut == matrix_identity_double4x4)
    }
}
