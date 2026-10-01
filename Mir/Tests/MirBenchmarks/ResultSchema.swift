// ResultSchema.swift
// MirBenchmarks
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// One launch of the benchmark suite: the machine it ran on and every sample it measured.
///
/// `Tools/MirBench` reads these files. Change ``currentSchemaVersion`` whenever the format changes.
struct LaunchResult: Codable {

    static let currentSchemaVersion = 1

    var schemaVersion = LaunchResult.currentSchemaVersion
    /// The commit that was measured, when the runner script passes it.
    var commit: String?
    /// Which launch of the run this was, counting from 1.
    var launchIndex: Int?
    var startedAt: Date
    var environment: EnvironmentInfo
    /// Reasons not to trust this launch's measurements. Empty for a clean launch.
    var contamination: [String]
    var benchmarks: [BenchmarkResult] = []
}

/// The measurements of one benchmark in one launch.
struct BenchmarkResult: Codable {
    var name: String
    var parameters: [String: String]
    /// The thermal state when the benchmark finished. Timings from a hot machine aren't comparable.
    var thermalStateAtEnd: String
    var metrics: [Metric]
}

/// One measured quantity and its samples.
struct Metric: Codable {

    /// How a metric can be gated, from most to least repeatable.
    enum Tier: Int, Codable {
        /// Exact counts of work, such as draw calls. The same on every machine.
        case workCounter = 1
        /// CPU counters, such as instructions retired. Nearly exact, but only on real hardware.
        case cpuCounter = 2
        /// Measured times and energy. Noisy; only comparable on the same dedicated machine.
        case measured = 3
    }

    var name: String
    var unit: String
    var tier: Tier
    var samples: [Double]
}

extension JSONEncoder {

    /// The encoder for benchmark results. Non-finite numbers become strings rather than failing.
    static var benchmarkResults: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        encoder.nonConformingFloatEncodingStrategy = .convertToString(
            positiveInfinity: "inf",
            negativeInfinity: "-inf",
            nan: "nan"
        )
        return encoder
    }
}
