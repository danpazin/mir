// Globe.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

/// The globe's surface, made of the 20 triangles of an icosahedron.
struct Globe {

    // MARK: - Properties

    /// The 20 triangles of the icosahedron.
    let patches: InlineArray<20, GlobePatch> = Icosahedron.makePatches()
}

