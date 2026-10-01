// Signposts.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import os

/// Signposts that mark renderer work on the Points of Interest track in Instruments.
///
/// Each frame's encoding shows up as an interval next to the CPU and GPU tracks, so a slow
/// frame in a trace can be matched to the work that made it slow. When nothing is recording,
/// a signpost costs a few nanoseconds.
enum Signposts {

    /// The signposter for frame encoding.
    static let renderer = OSSignposter(subsystem: "com.danpazin.mir", category: .pointsOfInterest)
}
