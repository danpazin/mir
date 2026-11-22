// Scene.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

/// Everything the renderer draws, and the camera it draws it from.
struct Scene {

    // MARK: - Properties

    /// The point of view the scene is drawn from.
    var camera: Camera
    /// The globe to draw.
    var globe: Globe

    // MARK: - Initializers

    /// Creates a scene with the default camera and the globe.
    init() {
        camera = Camera(coordinate: .init(latitude: 0.0, longitude: 0.0), distance: 3.0)
        globe = Globe()
    }
}
