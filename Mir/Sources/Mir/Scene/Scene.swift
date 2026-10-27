// Scene.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

struct Scene {

    // MARK: - Properties

    var camera: Camera
    var globe: Globe

    // MARK: - Initializers

    init() {
        camera = Camera()
        globe = Globe()
    }
}
