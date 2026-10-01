// NoiseSummary.swift
// MirBenchKit
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// How noisy each metric is in one run of several launches.
///
/// Two kinds of noise matter: between frames in one launch, and between launches. The second is
/// often larger, which is why the comparison treats a launch as one sample.
public struct NoiseSummary: Sendable {

    public struct Row: Sendable {
        public var benchmark: String
        public var metric: String
        public var unit: String
        public var tier: Metric.Tier
        /// The median of the per-launch medians.
        public var median: Double
        /// The coefficient of variation of the per-launch medians, or nil with fewer than 2 launches.
        public var launchToLaunch: Double?
        /// The median of each launch's own coefficient of variation, or nil for single-value metrics.
        public var frameToFrame: Double?
    }

    public var environment: EnvironmentInfo
    public var launches: Int
    public var rows: [Row]

    /// A plain-text table for the terminal.
    public func text() -> String {
        var lines = ["\(launches) launches on \(environment.summary)", ""]
        let header = "benchmark".padding(toLength: 30, withPad: " ", startingAt: 0)
            + "metric".padding(toLength: 14, withPad: " ", startingAt: 0)
            + "median".padding(toLength: 22, withPad: " ", startingAt: 0)
            + "launch CV".padding(toLength: 11, withPad: " ", startingAt: 0)
            + "frame CV"
        lines.append(header)
        for row in rows {
            let launchCV = row.launchToLaunch.map { String(format: "%.1f%%", $0 * 100) } ?? "-"
            let frameCV = row.frameToFrame.map { String(format: "%.1f%%", $0 * 100) } ?? "-"
            lines.append(
                row.benchmark.padding(toLength: 30, withPad: " ", startingAt: 0)
                    + row.metric.padding(toLength: 14, withPad: " ", startingAt: 0)
                    + format(row.median, unit: row.unit).padding(toLength: 22, withPad: " ", startingAt: 0)
                    + launchCV.padding(toLength: 11, withPad: " ", startingAt: 0)
                    + frameCV
            )
        }
        return lines.joined(separator: "\n")
    }
}

/// Summarizes the noise in each metric across a run's launches.
public func summarizeNoise(_ launches: [LaunchResult]) -> NoiseSummary {
    var rows: [NoiseSummary.Row] = []
    guard let reference = launches.first else {
        return NoiseSummary(environment: EnvironmentInfo(model: "none", os: "none", gpu: "none"), launches: 0, rows: [])
    }
    for benchmark in reference.benchmarks {
        for metric in benchmark.metrics {
            let sampleSets = launches.compactMap { launch in
                launch.benchmarks.first { $0.name == benchmark.name }?.metrics.first { $0.name == metric.name }?.samples
            }.filter { !$0.isEmpty }
            guard !sampleSets.isEmpty else { continue }
            let perLaunch = sampleSets.map(Statistics.median)
            let frameCVs = sampleSets.filter { $0.count > 1 }.map(Statistics.coefficientOfVariation)
            rows.append(NoiseSummary.Row(
                benchmark: benchmark.name,
                metric: metric.name,
                unit: metric.unit,
                tier: metric.tier,
                median: Statistics.median(perLaunch),
                launchToLaunch: perLaunch.count > 1 ? Statistics.coefficientOfVariation(perLaunch) : nil,
                frameToFrame: frameCVs.isEmpty ? nil : Statistics.median(frameCVs)
            ))
        }
    }
    return NoiseSummary(environment: reference.environment, launches: launches.count, rows: rows)
}
