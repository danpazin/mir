// Report.swift
// MirBenchKit
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

extension ComparisonReport {

    /// A Markdown report for a pull request comment or a CI job summary: regressions first.
    public func markdown() -> String {
        var lines: [String] = []
        let verdict = regressions.isEmpty ? "no regressions" : "\(regressions.count) regression\(regressions.count == 1 ? "" : "s")"
        lines.append("### Benchmarks: \(verdict), \(improvements.count) improvement\(improvements.count == 1 ? "" : "s")")
        lines.append("")
        let base = baseCommit.map { "`\($0)`" } ?? "base"
        let head = headCommit.map { "`\($0)`" } ?? "head"
        lines.append("\(base) (\(baseLaunches) launches) vs \(head) (\(headLaunches) launches) on \(environment.summary).")
        if !excludedLaunches.isEmpty {
            lines.append("")
            lines.append("Left out: " + excludedLaunches.joined(separator: "; "))
        }
        let shown = comparisons.filter { $0.verdict != .unchanged }
        if !shown.isEmpty {
            lines.append("")
            lines.append("| Verdict | Benchmark | Metric | Base | Head | Change | p |")
            lines.append("| --- | --- | --- | --- | --- | --- | --- |")
            for item in shown {
                let verdictText = item.verdict == .regression ? "**regression**" : item.verdict.rawValue
                let p = item.pValue.map { String(format: "%.3f", $0) } ?? "exact"
                let note = item.note.map { " (\($0))" } ?? ""
                lines.append("| \(verdictText) | \(item.benchmark) | \(item.metric)\(note) | \(format(item.baseValue, unit: item.unit)) | \(format(item.headValue, unit: item.unit)) | \(formatChange(item.changePercent)) | \(p) |")
            }
        }
        let unchanged = comparisons.count - shown.count
        lines.append("")
        lines.append("\(unchanged) of \(comparisons.count) metrics unchanged.")
        return lines.joined(separator: "\n")
    }
}

/// Formats a value in its unit, scaled so it reads at a glance.
public func format(_ value: Double, unit: String) -> String {
    switch unit {
    case "bytes":
        let units = ["B", "KB", "MB", "GB"]
        var scaled = value
        var index = 0
        while abs(scaled) >= 1_024 && index < units.count - 1 {
            scaled /= 1_024
            index += 1
        }
        return index == 0 ? String(format: "%.0f B", scaled) : String(format: "%.2f %@", scaled, units[index])
    case "count":
        return String(format: "%.0f", value)
    case "ms":
        return String(format: "%.3f ms", value)
    default:
        if abs(value) >= 1_000_000 {
            return String(format: "%.2f M %@", value / 1_000_000, unit)
        }
        return String(format: "%.1f %@", value, unit)
    }
}

private func formatChange(_ percent: Double) -> String {
    guard percent.isFinite else { return "new" }
    return String(format: "%+.1f%%", percent)
}
