// StatisticsTests.swift
// MirBenchKitTests
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MirBenchKit
import Testing

@Suite("Statistics")
struct StatisticsTests {

    @Test("The median ignores an outlier")
    func medianIgnoresOutlier() {
        #expect(Statistics.median([10, 11, 12, 100]) == 11.5)
        #expect(Statistics.median([3, 1, 2]) == 2)
    }

    @Test("Percentiles interpolate between neighbours")
    func percentiles() {
        let values: [Double] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        #expect(Statistics.percentile(values, 0) == 1)
        #expect(Statistics.percentile(values, 100) == 10)
        #expect(abs(Statistics.percentile(values, 90) - 9.1) < 1e-9)
    }

    @Test("The coefficient of variation is spread relative to the mean")
    func coefficientOfVariation() {
        #expect(Statistics.coefficientOfVariation([5, 5, 5]) == 0)
        let cv = Statistics.coefficientOfVariation([9, 10, 11])
        #expect(abs(cv - 0.1) < 1e-9)
    }

    @Test("Five slower launches out of five give the smallest exact p-value, 1/252")
    func smallestExactPValue() {
        let p = Statistics.mannWhitneyGreater(head: [11, 12, 13, 14, 15], base: [1, 2, 3, 4, 5])
        #expect(abs(p - 1.0 / 252) < 1e-12)
    }

    @Test("Head that is never larger gives p = 1")
    func neverLarger() {
        #expect(Statistics.mannWhitneyGreater(head: [1, 2, 3], base: [4, 5, 6]) == 1)
    }

    @Test("Interleaved samples are not significant")
    func interleavedSamples() {
        let p = Statistics.mannWhitneyGreater(head: [1, 3, 5, 7, 9], base: [2, 4, 6, 8, 10])
        #expect(p > 0.3)
    }

    @Test("The exact p-value matches a textbook table value")
    func textbookValue() {
        // Three head values above all four base values: U = 12 = m × n, p = 1 / C(7, 3) = 1/35.
        let p = Statistics.mannWhitneyGreater(head: [10, 11, 12], base: [1, 2, 3, 4])
        #expect(abs(p - 1.0 / 35) < 1e-12)
    }

    @Test("Large samples use the normal approximation and still find a clear shift")
    func normalApproximation() {
        let base = (0..<30).map { 100 + Double($0 % 7) }
        let head = base.map { $0 * 1.2 }
        #expect(Statistics.mannWhitneyGreater(head: head, base: base) < 0.001)
        #expect(Statistics.mannWhitneyGreater(head: base, base: base) > 0.3)
    }
}
