// Comparison.swift
// MirBenchKit
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// The verdict on one metric of one benchmark, base against head.
public struct MetricComparison: Sendable {

    public enum Verdict: String, Sendable {
        case regression
        case improvement
        case unchanged
        case notGated = "not gated"
    }

    public var benchmark: String
    public var metric: String
    public var unit: String
    public var tier: Metric.Tier
    /// The median across base launches of each launch's median.
    public var baseValue: Double
    /// The median across head launches of each launch's median.
    public var headValue: Double
    public var changePercent: Double
    /// The Mann–Whitney p-value in the direction of the change; nil for exact counters.
    public var pValue: Double?
    public var verdict: Verdict
    public var note: String?
}

/// Every metric compared, plus what was left out and why.
public struct ComparisonReport: Sendable {
    public var environment: EnvironmentInfo
    public var baseCommit: String?
    public var headCommit: String?
    public var baseLaunches: Int
    public var headLaunches: Int
    /// Launches left out because their conditions would distort the numbers.
    public var excludedLaunches: [String]
    public var comparisons: [MetricComparison]

    public var regressions: [MetricComparison] { comparisons.filter { $0.verdict == .regression } }
    public var improvements: [MetricComparison] { comparisons.filter { $0.verdict == .improvement } }
}

public enum ComparisonError: Error, CustomStringConvertible {
    case noCleanLaunches(side: String)
    case differentMachines(base: String, head: String)

    public var description: String {
        switch self {
        case .noCleanLaunches(let side):
            "Every \(side) launch was contaminated, so there is nothing trustworthy to compare"
        case .differentMachines(let base, let head):
            "Base ran on \(base) but head ran on \(head); numbers from different machines aren't compared"
        }
    }
}

/// Compares head launches against base launches, metric by metric.
///
/// The unit of comparison is a launch: each launch's samples collapse to their median first, so
/// frames within a launch, which aren't independent, don't inflate the evidence. Then:
/// - Exact work counters fail on any increase beyond their limit (0% by default).
/// - CPU counters and measured values fail only if the median grew beyond the limit AND the
///   one-sided Mann–Whitney test says the growth is unlikely to be noise (p < alpha).
/// - In a virtual machine only exact work counters are gated.
public func compare(base: [LaunchResult], head: [LaunchResult], thresholds: Thresholds = .standard) throws -> ComparisonReport {
    var excluded: [String] = []
    func clean(_ launches: [LaunchResult], side: String) -> [LaunchResult] {
        launches.filter { launch in
            guard launch.contamination.isEmpty else {
                excluded.append("\(side) launch \(launch.launchIndex ?? 0): \(launch.contamination.joined(separator: "; "))")
                return false
            }
            return true
        }
    }
    let cleanBase = clean(base, side: "base")
    let cleanHead = clean(head, side: "head")
    guard let baseEnvironment = cleanBase.first?.environment else { throw ComparisonError.noCleanLaunches(side: "base") }
    guard let headEnvironment = cleanHead.first?.environment else { throw ComparisonError.noCleanLaunches(side: "head") }
    for launch in cleanBase + cleanHead where !launch.environment.isComparable(to: baseEnvironment) {
        throw ComparisonError.differentMachines(base: baseEnvironment.summary, head: launch.environment.summary)
    }

    var comparisons: [MetricComparison] = []
    let benchmarkNames = cleanHead.first!.benchmarks.map(\.name)
    for name in benchmarkNames {
        guard let headReference = cleanHead.first!.benchmarks.first(where: { $0.name == name }) else { continue }
        for metric in headReference.metrics {
            let baseValues = perLaunchValues(of: metric, in: name, launches: cleanBase)
            let headValues = perLaunchValues(of: metric, in: name, launches: cleanHead)
            guard !baseValues.isEmpty, !headValues.isEmpty else { continue }
            comparisons.append(judge(
                benchmark: name,
                metric: metric,
                baseValues: baseValues,
                headValues: headValues,
                virtualMachine: headEnvironment.virtualMachine,
                thresholds: thresholds
            ))
        }
    }
    let order: [MetricComparison.Verdict] = [.regression, .improvement, .unchanged, .notGated]
    comparisons.sort { lhs, rhs in
        let left = order.firstIndex(of: lhs.verdict)!
        let right = order.firstIndex(of: rhs.verdict)!
        return left != right ? left < right : (lhs.benchmark, lhs.metric) < (rhs.benchmark, rhs.metric)
    }
    return ComparisonReport(
        environment: headEnvironment,
        baseCommit: cleanBase.first?.commit,
        headCommit: cleanHead.first?.commit,
        baseLaunches: cleanBase.count,
        headLaunches: cleanHead.count,
        excludedLaunches: excluded,
        comparisons: comparisons
    )
}

/// One value per launch: the median of that launch's samples. Measured values from a launch that
/// ended a benchmark hot are left out, because throttled clocks make them incomparable.
private func perLaunchValues(of metric: Metric, in benchmark: String, launches: [LaunchResult]) -> [Double] {
    launches.compactMap { launch in
        guard
            let result = launch.benchmarks.first(where: { $0.name == benchmark }),
            let match = result.metrics.first(where: { $0.name == metric.name }),
            !match.samples.isEmpty
        else {
            return nil
        }
        if metric.tier == .measured && result.thermalStateAtEnd != "nominal" {
            return nil
        }
        return Statistics.median(match.samples)
    }
}

private func judge(
    benchmark: String,
    metric: Metric,
    baseValues: [Double],
    headValues: [Double],
    virtualMachine: Bool,
    thresholds: Thresholds
) -> MetricComparison {
    let baseValue = Statistics.median(baseValues)
    let headValue = Statistics.median(headValues)
    let changePercent: Double
    if baseValue == 0 {
        changePercent = headValue == 0 ? 0 : .infinity
    } else {
        changePercent = (headValue - baseValue) / baseValue * 100
    }
    var comparison = MetricComparison(
        benchmark: benchmark,
        metric: metric.name,
        unit: metric.unit,
        tier: metric.tier,
        baseValue: baseValue,
        headValue: headValue,
        changePercent: changePercent,
        pValue: nil,
        verdict: .unchanged,
        note: nil
    )
    let rule = thresholds.rule(for: metric.name, tier: metric.tier)
    guard rule.gated else {
        comparison.verdict = .notGated
        comparison.note = rule.reason
        return comparison
    }
    if virtualMachine && metric.tier != .workCounter {
        comparison.verdict = .notGated
        comparison.note = "Virtual machine: only exact work counters are meaningful"
        return comparison
    }
    switch metric.tier {
    case .workCounter:
        if headValue > baseValue * (1 + rule.maxIncreasePercent / 100) {
            comparison.verdict = .regression
        } else if headValue < baseValue {
            comparison.verdict = .improvement
        }
    case .cpuCounter, .measured:
        if changePercent > rule.maxIncreasePercent {
            let p = Statistics.mannWhitneyGreater(head: headValues, base: baseValues)
            comparison.pValue = p
            if p < thresholds.alpha {
                comparison.verdict = .regression
            } else {
                comparison.note = "Grew \(String(format: "%.1f", changePercent))%, but within noise"
            }
        } else if changePercent < -rule.maxIncreasePercent {
            let p = Statistics.mannWhitneyGreater(head: baseValues, base: headValues)
            comparison.pValue = p
            if p < thresholds.alpha {
                comparison.verdict = .improvement
            }
        }
    }
    return comparison
}
