// Scene.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

struct Scene {

    // MARK: - Properties

    var camera: Camera

    // MARK: - Initializers

    init() {
        camera = Camera(
            position: [0, 0, 3],
            target: [0, 0, 0],
            up: [0, 1, 0],
            fov: (Float.pi / 4),
            near: 0.01,
            far: 100,
            aspectRatio: 1
        )
    }
}
