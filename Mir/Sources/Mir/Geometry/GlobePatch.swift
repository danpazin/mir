// GlobePatch.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import simd

/// One triangle of the globe's surface.
struct GlobePatch {

    // MARK: - Properties

    /// The three corner positions on the unit sphere.
    let vertices: InlineArray<3, SIMD3<Float>>
}
