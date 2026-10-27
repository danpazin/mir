// Globe.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

/// The 3D globe model, built from a base icosahedron subdivided by LOD.
struct Globe {

    // MARK: - Properties

    /// The 20 root patches of the icosahedron base mesh.
    let patches: InlineArray<20, GlobePatch> = Icosahedron.makePatches()
}

