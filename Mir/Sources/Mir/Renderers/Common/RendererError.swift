// RendererError.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// Errors that can occur while configuring/compiling a renderer or drawing a frame.
package enum RendererError: LocalizedError {

    case missingVertexFunction(name: String)
    case missingFragmentFunction(name: String)
    case textureUnavailable
    case encodingUnavailable
    case bufferTooSmall(needed: Int, available: Int)
    case gpuTimeout
    case gpuFailure(description: String)

    package var errorDescription: String? {
        switch self {
        case .missingVertexFunction(let name):
            return "Missing vertex shader function \"\(name)\"."
        case .missingFragmentFunction(let name):
            return "Missing fragment shader function \"\(name)\"."
        case .textureUnavailable:
            return "The render target texture could not be created."
        case .encodingUnavailable:
            return "The frame could not be encoded: the render pipeline or a GPU resource is missing."
        case .bufferTooSmall(let needed, let available):
            return "The scene needs a \(needed)-byte vertex buffer, but the renderer has \(available) bytes."
        case .gpuTimeout:
            return "The GPU did not finish the frame in time."
        case .gpuFailure(let description):
            return "The GPU failed to render the frame: \(description)"
        }
    }
}
