// FrameTiming.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

/// How long one offscreen frame took, measured where the renderer knows the boundaries.
package struct FrameTiming: Sendable {

    // MARK: - Properties

    /// CPU time to make the command buffer and encode the frame, in seconds.
    package var encodeSeconds: Double
    /// GPU time from the GPU's own start and end timestamps, in seconds.
    package var gpuSeconds: Double
    /// Time from the start of the call until the CPU saw the GPU finish, in seconds.
    package var totalSeconds: Double

    // MARK: - Initializers

    package init(encodeSeconds: Double, gpuSeconds: Double, totalSeconds: Double) {
        self.encodeSeconds = encodeSeconds
        self.gpuSeconds = gpuSeconds
        self.totalSeconds = totalSeconds
    }
}

extension Duration {

    /// The duration as a number of seconds.
    package var inSeconds: Double {
        Double(components.seconds) + Double(components.attoseconds) * 1e-18
    }
}
