// Scene.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

package struct Scene {

    // MARK: - Properties

    package var camera: Camera
    package var globe: Globe

    // MARK: - Initializers

    package init() {
        camera = Camera(
            bearing: .degrees(0),
            pitch: 0,
            coordinate: .init(),
            fov: .degrees(60),
            near: 0.01,
            far: 100,
            zoom: -0.25,
            aspectRatio: 1
        )
        globe = Globe()
    }
}
