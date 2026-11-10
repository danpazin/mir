// Lens.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

/// The part of the camera that decides how much of the world fits on the screen.
struct Lens {
    
    // MARK: - Properties
    
    /// How wide the lens sees, in degrees, across the shorter side of the view.
    let fieldOfView: Double = 50.0
    
    /// How many times bigger things look than through a 90° lens.
    var magnification: Double {
        let halfAngleInRadians = fieldOfView * 0.5 * .pi / 180.0
        return 1.0 / tan(halfAngleInRadians)
    }
}
