// Statistics.swift
// MirBenchKit
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// The statistics the comparison needs, kept small enough to read in one sitting.
public enum Statistics {

    /// The middle value. Robust: one outlier frame barely moves it.
    public static func median(_ values: [Double]) -> Double {
        percentile(values, 50)
    }

    /// The value below which `percent` of the values fall, interpolating between neighbours.
    public static func percentile(_ values: [Double], _ percent: Double) -> Double {
        precondition(!values.isEmpty, "Percentile of no values")
        let sorted = values.sorted()
        let position = Double(sorted.count - 1) * percent / 100
        let lower = Int(position.rounded(.down))
        let upper = Int(position.rounded(.up))
        let fraction = position - Double(lower)
        return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
    }

    public static func mean(_ values: [Double]) -> Double {
        values.reduce(0, +) / Double(values.count)
    }

    public static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = mean(values)
        let squares = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
        return (squares / Double(values.count - 1)).squareRoot()
    }

    /// Standard deviation as a fraction of the mean: how noisy a metric is, independent of its units.
    public static func coefficientOfVariation(_ values: [Double]) -> Double {
        let mean = mean(values)
        return mean == 0 ? 0 : standardDeviation(values) / mean
    }

    /// The median distance from the median: a spread measure that ignores outliers.
    public static func medianAbsoluteDeviation(_ values: [Double]) -> Double {
        let center = median(values)
        return median(values.map { abs($0 - center) })
    }

    // MARK: - Mann–Whitney U

    /// The one-sided Mann–Whitney U test: how likely values from `head` would come out at least
    /// this much larger than values from `base` if both came from the same distribution.
    ///
    /// It compares ranks, not values, so it assumes no bell curve; timing data rarely has one.
    /// Small samples use the exact distribution, so with 5 launches against 5 the smallest
    /// possible p-value is 1/252 ≈ 0.004. Larger samples use the normal approximation.
    ///
    /// - Returns: The p-value; small means `head` is very likely larger.
    public static func mannWhitneyGreater(head: [Double], base: [Double]) -> Double {
        let m = head.count
        let n = base.count
        precondition(m > 0 && n > 0, "Mann–Whitney needs samples on both sides")
        // U counts the (base, head) pairs where head is larger; a tie counts as half.
        var u = 0.0
        for h in head {
            for b in base {
                if h > b {
                    u += 1
                } else if h == b {
                    u += 0.5
                }
            }
        }
        if m <= 20 && n <= 20 {
            return exactUpperTail(atLeast: u, m: m, n: n)
        }
        let mean = Double(m * n) / 2
        let deviation = (Double(m * n * (m + n + 1)) / 12).squareRoot()
        let z = (u - 0.5 - mean) / deviation
        return 0.5 * erfc(z / 2.squareRoot())
    }

    /// P(U ≥ u) when all orderings of m head values and n base values are equally likely.
    ///
    /// count[j][k][s] would be the number of orderings of j head and k base values with U = s.
    /// The largest value is either a head value (beating all k base values) or a base value
    /// (beating none), which gives count[j][k][s] = count[j-1][k][s-k] + count[j][k-1][s].
    private static func exactUpperTail(atLeast u: Double, m: Int, n: Int) -> Double {
        let maxU = m * n
        var table = Array(repeating: Array(repeating: [Double](repeating: 0, count: maxU + 1), count: n + 1), count: m + 1)
        for j in 0...m {
            for k in 0...n {
                if j == 0 || k == 0 {
                    table[j][k][0] = 1
                    continue
                }
                for s in 0...(j * k) {
                    let headLargest = s >= k ? table[j - 1][k][s - k] : 0
                    let baseLargest = table[j][k - 1][s]
                    table[j][k][s] = headLargest + baseLargest
                }
            }
        }
        let distribution = table[m][n]
        let total = distribution.reduce(0, +)
        let threshold = Int(u.rounded(.up))
        guard threshold <= maxU else { return 0 }
        let tail = distribution[threshold...].reduce(0, +)
        return tail / total
    }
}
