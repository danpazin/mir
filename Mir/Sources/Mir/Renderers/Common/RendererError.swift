// RendererError.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// Errors that can occur while configuring/compiling a renderer.
enum RendererError: LocalizedError {

    /// The shader library has no vertex function with this name.
    case missingVertexFunction(name: String)
    /// The shader library has no fragment function with this name.
    case missingFragmentFunction(name: String)

    /// A message that names the missing function.
    var errorDescription: String? {
        switch self {
        case .missingVertexFunction(let name):
            return "Missing vertex shader function \"\(name)\"."
        case .missingFragmentFunction(let name):
            return "Missing fragment shader function \"\(name)\"."
        }
    }
}
