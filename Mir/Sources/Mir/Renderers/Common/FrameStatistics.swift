// FrameStatistics.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

/// How much work a renderer asked of the GPU for one frame.
///
/// Unlike timings, these counts are exact and the same on every machine, so a test can hold
/// them to a budget anywhere, including on a noisy CI virtual machine.
package struct FrameStatistics: Equatable, Sendable {

    // MARK: - Properties

    /// The number of draw calls encoded.
    package var drawCalls = 0
    /// The number of vertices those draw calls submit.
    package var vertexCount = 0
    /// The number of bytes the CPU copied for the GPU: uniforms, vertex bytes and buffer contents.
    package var uploadedBytes = 0

    // MARK: - Initializers

    package init() {}
}
