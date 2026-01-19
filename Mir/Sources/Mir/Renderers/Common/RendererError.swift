// RendererError.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// Errors that can occur while configuring/compiling a renderer.
enum RendererError: Error {

    case missingVertexFunction(name: String)
    case missingFragmentFunction(name: String)

    var errorDescription: String? {
        switch self {
        case .missingVertexFunction(let name):
            return "Missing vertex shader function \"\(name)\"."
        case .missingFragmentFunction(let name):
            return "Missing fragment shader function \"\(name)\"."
        }
    }
}
