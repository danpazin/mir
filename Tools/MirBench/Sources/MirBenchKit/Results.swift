// Results.swift
// MirBenchKit
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

// These types mirror the JSON the MirBenchmarks suite writes (Mir/Tests/MirBenchmarks/ResultSchema.swift).
// They are a copy rather than a shared module so this tool builds without Metal; the schema
// version check below catches the two drifting apart.

/// One launch of the benchmark suite.
public struct LaunchResult: Codable, Sendable {
    public static let supportedSchemaVersion = 1

    public var schemaVersion: Int
    public var commit: String?
    public var launchIndex: Int?
    public var startedAt: Date
    public var environment: EnvironmentInfo
    public var contamination: [String]
    public var benchmarks: [BenchmarkResult]

    public init(
        schemaVersion: Int = LaunchResult.supportedSchemaVersion,
        commit: String? = nil,
        launchIndex: Int? = nil,
        startedAt: Date = Date(timeIntervalSince1970: 0),
        environment: EnvironmentInfo,
        contamination: [String] = [],
        benchmarks: [BenchmarkResult]
    ) {
        self.schemaVersion = schemaVersion
        self.commit = commit
        self.launchIndex = launchIndex
        self.startedAt = startedAt
        self.environment = environment
        self.contamination = contamination
        self.benchmarks = benchmarks
    }
}

/// The machine and conditions a launch ran under.
public struct EnvironmentInfo: Codable, Sendable {
    public var model: String
    public var machine: String
    public var cpu: String?
    public var os: String
    public var gpu: String
    public var supportsMetal4: Bool
    public var virtualMachine: Bool
    public var buildConfiguration: String
    public var thermalStateAtStart: String
    public var lowPowerMode: Bool
    public var validationLayer: Bool
    public var debuggerAttached: Bool
    public var qualityOfService: String

    public init(
        model: String,
        machine: String = "arm64",
        cpu: String? = nil,
        os: String,
        gpu: String,
        supportsMetal4: Bool = true,
        virtualMachine: Bool = false,
        buildConfiguration: String = "release",
        thermalStateAtStart: String = "nominal",
        lowPowerMode: Bool = false,
        validationLayer: Bool = false,
        debuggerAttached: Bool = false,
        qualityOfService: String = "user-interactive"
    ) {
        self.model = model
        self.machine = machine
        self.cpu = cpu
        self.os = os
        self.gpu = gpu
        self.supportsMetal4 = supportsMetal4
        self.virtualMachine = virtualMachine
        self.buildConfiguration = buildConfiguration
        self.thermalStateAtStart = thermalStateAtStart
        self.lowPowerMode = lowPowerMode
        self.validationLayer = validationLayer
        self.debuggerAttached = debuggerAttached
        self.qualityOfService = qualityOfService
    }

    /// A short description of the machine, for reports.
    public var summary: String {
        "\(model) (\(gpu)), \(os)\(virtualMachine ? ", virtual machine" : "")"
    }

    /// Whether two launches ran on the same kind of machine and software, so their numbers compare.
    public func isComparable(to other: EnvironmentInfo) -> Bool {
        model == other.model && gpu == other.gpu && os == other.os && virtualMachine == other.virtualMachine
    }
}

/// The measurements of one benchmark in one launch.
public struct BenchmarkResult: Codable, Sendable {
    public var name: String
    public var parameters: [String: String]
    public var thermalStateAtEnd: String
    public var metrics: [Metric]

    public init(name: String, parameters: [String: String] = [:], thermalStateAtEnd: String = "nominal", metrics: [Metric]) {
        self.name = name
        self.parameters = parameters
        self.thermalStateAtEnd = thermalStateAtEnd
        self.metrics = metrics
    }
}

/// One measured quantity and its samples.
public struct Metric: Codable, Sendable {

    /// How a metric can be gated, from most to least repeatable.
    public enum Tier: Int, Codable, Sendable, Comparable {
        /// Exact counts of work, the same on every machine.
        case workCounter = 1
        /// CPU counters such as instructions retired: nearly exact, real hardware only.
        case cpuCounter = 2
        /// Times and energy: noisy, comparable only on the same dedicated machine.
        case measured = 3

        public static func < (lhs: Tier, rhs: Tier) -> Bool { lhs.rawValue < rhs.rawValue }
    }

    public var name: String
    public var unit: String
    public var tier: Tier
    public var samples: [Double]

    public init(name: String, unit: String, tier: Tier, samples: [Double]) {
        self.name = name
        self.unit = unit
        self.tier = tier
        self.samples = samples
    }
}

// MARK: - Loading

public enum ResultsError: Error, CustomStringConvertible {
    case noResults(URL)
    case unsupportedSchema(URL, Int)

    public var description: String {
        switch self {
        case .noResults(let url):
            "No benchmark results (mir-bench-*.json) in \(url.path)"
        case .unsupportedSchema(let url, let version):
            "\(url.lastPathComponent) uses schema version \(version); this tool reads version \(LaunchResult.supportedSchemaVersion)"
        }
    }
}

extension LaunchResult {

    /// Loads every launch in a directory written by `scripts/bench.sh`, in launch order.
    public static func load(from directory: URL) throws -> [LaunchResult] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "inf",
            negativeInfinity: "-inf",
            nan: "nan"
        )
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("mir-bench-") && $0.pathExtension == "json" }
        var launches: [LaunchResult] = []
        for file in files {
            let launch = try decoder.decode(LaunchResult.self, from: Data(contentsOf: file))
            guard launch.schemaVersion == supportedSchemaVersion else {
                throw ResultsError.unsupportedSchema(file, launch.schemaVersion)
            }
            launches.append(launch)
        }
        guard !launches.isEmpty else { throw ResultsError.noResults(directory) }
        return launches.sorted { ($0.launchIndex ?? 0) < ($1.launchIndex ?? 0) }
    }
}
