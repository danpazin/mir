// ComparisonTests.swift
// MirBenchKitTests
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MirBenchKit
import Testing

/// Checks the gate itself: it must stay quiet on noise and fire on real changes.
@Suite("Comparison")
struct ComparisonTests {

    /// Launch-to-launch jitter of about ±2%, the same pattern on both sides of an A/A comparison.
    static let jitter: [Double] = [1.00, 1.02, 0.99, 1.01, 0.98]

    static let mac = EnvironmentInfo(model: "Mac16,7", os: "26.7.1", gpu: "Apple M4 Pro")

    /// Makes launches whose encode time is `encodeMilliseconds` scaled by the jitter pattern.
    static func launches(
        encodeMilliseconds: Double,
        drawCalls: Double = 5_120,
        jitter: [Double] = jitter,
        environment: EnvironmentInfo = mac,
        contamination: [String] = [],
        thermalStateAtEnd: String = "nominal"
    ) -> [LaunchResult] {
        jitter.enumerated().map { index, factor in
            let encode = encodeMilliseconds * factor
            return LaunchResult(
                launchIndex: index + 1,
                environment: environment,
                contamination: contamination,
                benchmarks: [
                    BenchmarkResult(
                        name: "frame/metal/1080p/level4",
                        thermalStateAtEnd: thermalStateAtEnd,
                        metrics: [
                            Metric(name: "draw calls", unit: "count", tier: .workCounter, samples: [drawCalls]),
                            Metric(name: "encode", unit: "ms", tier: .measured, samples: [encode * 0.99, encode, encode * 1.01])
                        ]
                    )
                ]
            )
        }
    }

    private func verdict(of metric: String, in report: ComparisonReport) -> MetricComparison.Verdict? {
        report.comparisons.first { $0.metric == metric }?.verdict
    }

    @Test("A commit compared with itself has no regressions")
    func aaComparison() throws {
        let base = Self.launches(encodeMilliseconds: 0.43)
        let head = Self.launches(encodeMilliseconds: 0.43, jitter: Self.jitter.reversed())
        let report = try compare(base: base, head: head)
        #expect(report.regressions.isEmpty)
        #expect(report.improvements.isEmpty)
    }

    @Test("A 15% slower encode is a regression")
    func injectedSlowdown() throws {
        let report = try compare(base: Self.launches(encodeMilliseconds: 0.43), head: Self.launches(encodeMilliseconds: 0.43 * 1.15))
        #expect(verdict(of: "encode", in: report) == .regression)
    }

    @Test("A 5% slower encode is within the 10% threshold")
    func slowdownBelowThreshold() throws {
        let report = try compare(base: Self.launches(encodeMilliseconds: 0.43), head: Self.launches(encodeMilliseconds: 0.43 * 1.05))
        #expect(verdict(of: "encode", in: report) == .unchanged)
    }

    @Test("A large change that is still noise isn't a regression")
    func largeButNoisyChange() throws {
        let base = Self.launches(encodeMilliseconds: 0.43, jitter: [0.7, 1.4, 0.8, 1.5, 0.9])
        let head = Self.launches(encodeMilliseconds: 0.43, jitter: [1.3, 0.8, 1.6, 0.9, 1.2])
        let report = try compare(base: base, head: head)
        #expect(verdict(of: "encode", in: report) == .unchanged)
    }

    @Test("One extra draw call is a regression; one fewer is an improvement")
    func exactCounters() throws {
        let base = Self.launches(encodeMilliseconds: 0.43)
        let more = try compare(base: base, head: Self.launches(encodeMilliseconds: 0.43, drawCalls: 5_121))
        #expect(verdict(of: "draw calls", in: more) == .regression)
        let fewer = try compare(base: base, head: Self.launches(encodeMilliseconds: 0.43, drawCalls: 5_119))
        #expect(verdict(of: "draw calls", in: fewer) == .improvement)
    }

    @Test("In a virtual machine only exact counters are gated")
    func virtualMachine() throws {
        var vm = Self.mac
        vm.virtualMachine = true
        let base = Self.launches(encodeMilliseconds: 0.43, environment: vm)
        let head = Self.launches(encodeMilliseconds: 0.9, drawCalls: 5_121, environment: vm)
        let report = try compare(base: base, head: head)
        #expect(verdict(of: "encode", in: report) == .notGated)
        #expect(verdict(of: "draw calls", in: report) == .regression)
    }

    @Test("Contaminated launches are left out")
    func contaminatedLaunches() throws {
        let base = Self.launches(encodeMilliseconds: 0.43)
        let head = Self.launches(encodeMilliseconds: 0.43) + Self.launches(encodeMilliseconds: 5, contamination: ["A debugger is attached"])
        let report = try compare(base: base, head: head)
        #expect(report.headLaunches == 5)
        #expect(report.excludedLaunches.count == 5)
        #expect(report.regressions.isEmpty)
    }

    @Test("If every launch is contaminated there is nothing to compare")
    func onlyContaminatedLaunches() {
        let base = Self.launches(encodeMilliseconds: 0.43)
        let head = Self.launches(encodeMilliseconds: 0.43, contamination: ["Metal API validation is on"])
        #expect(throws: ComparisonError.self) {
            try compare(base: base, head: head)
        }
    }

    @Test("Runs from different machines aren't compared")
    func differentMachines() {
        let other = EnvironmentInfo(model: "Mac15,3", os: "26.7.1", gpu: "Apple M3")
        #expect(throws: ComparisonError.self) {
            try compare(base: Self.launches(encodeMilliseconds: 0.43), head: Self.launches(encodeMilliseconds: 0.43, environment: other))
        }
    }

    @Test("Timings from a benchmark that ended hot are left out")
    func hotBenchmark() throws {
        let base = Self.launches(encodeMilliseconds: 0.43)
        let head = Self.launches(encodeMilliseconds: 0.9, thermalStateAtEnd: "serious")
        let report = try compare(base: base, head: head)
        #expect(verdict(of: "encode", in: report) == nil)
        #expect(verdict(of: "draw calls", in: report) == .unchanged)
    }

    @Test("The report lists regressions first")
    func reportOrder() throws {
        let report = try compare(
            base: Self.launches(encodeMilliseconds: 0.43),
            head: Self.launches(encodeMilliseconds: 0.43 * 1.5, drawCalls: 5_000)
        )
        #expect(report.comparisons.first?.verdict == .regression)
        let markdown = report.markdown()
        #expect(markdown.contains("1 regression"))
        #expect(markdown.contains("**regression**"))
    }
}
