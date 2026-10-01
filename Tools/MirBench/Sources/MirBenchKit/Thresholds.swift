// Thresholds.swift
// MirBenchKit
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// When a change counts as a regression: the acceptance criteria, as data that changes by review.
public struct Thresholds: Codable, Sendable {

    /// An override for one metric, by name.
    public struct MetricRule: Codable, Sendable {
        public var gated: Bool?
        public var maxIncreasePercent: Double?
        /// Why the rule exists, shown in reports.
        public var reason: String?

        public init(gated: Bool? = nil, maxIncreasePercent: Double? = nil, reason: String? = nil) {
            self.gated = gated
            self.maxIncreasePercent = maxIncreasePercent
            self.reason = reason
        }
    }

    /// The largest p-value that counts as "unlikely to be noise".
    public var alpha: Double
    /// The largest allowed increase per tier, keyed by tier number ("1", "2", "3").
    public var maxIncreasePercent: [String: Double]
    public var metrics: [String: MetricRule]

    public init(alpha: Double, maxIncreasePercent: [String: Double], metrics: [String: MetricRule] = [:]) {
        self.alpha = alpha
        self.maxIncreasePercent = maxIncreasePercent
        self.metrics = metrics
    }

    /// Exact counters may not grow at all; instructions may grow 2%; times 10%.
    public static let standard = Thresholds(alpha: 0.01, maxIncreasePercent: ["1": 0, "2": 2, "3": 10])

    public static func load(from url: URL) throws -> Thresholds {
        try JSONDecoder().decode(Thresholds.self, from: Data(contentsOf: url))
    }

    /// The rule that applies to a metric.
    public func rule(for metric: String, tier: Metric.Tier) -> (gated: Bool, maxIncreasePercent: Double, reason: String?) {
        let override = metrics[metric]
        let tierKey = String(tier.rawValue)
        let tierLimit = maxIncreasePercent[tierKey] ?? Thresholds.standard.maxIncreasePercent[tierKey] ?? 0
        return (override?.gated ?? true, override?.maxIncreasePercent ?? tierLimit, override?.reason)
    }
}
