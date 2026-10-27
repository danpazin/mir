// Uniforms+Camera.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import CoreFoundation
import MirSharedTypes

extension Uniforms {
    
    init(camera: Camera, drawableSize: CGSize) {
        self.init(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: float4x4(camera.viewMatrix),
            projectionMatrix: float4x4(camera.projectionMatrix(drawableSize: drawableSize))
        )
    }
}
