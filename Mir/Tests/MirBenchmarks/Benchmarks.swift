// Benchmarks.swift
// MirBenchmarks
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation
import Metal
import Mir
import Testing

/// The benchmark suite.
///
/// It runs only when `MIR_BENCH=1` (pass `TEST_RUNNER_MIR_BENCH=1` to `xcodebuild`), and is meant
/// for Release builds: `scripts/bench.sh` builds it once and runs it in several separate launches.
/// Every benchmark renders offscreen with fixed inputs, warms up first, and records every sample,
/// so the analysis tool can judge noise for itself.
@MainActor
@Suite("Benchmarks", .serialized, .enabled(if: BenchmarkSettings.isEnabled))
struct Benchmarks {

    @Test("Run the benchmarks")
    func runBenchmarks() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let settings = BenchmarkSettings.current
        let environment = EnvironmentInfo.capture(device: device)
        var launch = LaunchResult(
            commit: settings.commit,
            launchIndex: settings.launchIndex,
            startedAt: Date(),
            environment: environment,
            contamination: environment.contamination
        )
        for reason in launch.contamination {
            print("[mir-bench] warning: \(reason)")
        }
        for benchmark in Self.catalog(device: device) where settings.includes(benchmark.name) {
            waitForNominalThermalState()
            let metrics = try benchmark.run(device, settings)
            let result = BenchmarkResult(
                name: benchmark.name,
                parameters: benchmark.parameters,
                thermalStateAtEnd: ProcessInfo.processInfo.thermalState.name,
                metrics: metrics
            )
            print("[mir-bench] \(summary(of: result))")
            launch.benchmarks.append(result)
        }
        #expect(!launch.benchmarks.isEmpty, "No benchmark matched the filter \"\(settings.filter ?? "")\"")
        try record(launch, settings: settings)
    }

    // MARK: - Catalog

    /// Every benchmark, in the fixed order they run.
    static func catalog(device: MTLDevice) -> [Benchmark] {
        var renderers = ["metal"]
        #if !targetEnvironment(simulator)
        if device.supportsFamily(.metal4) {
            renderers.append("metal4")
        }
        #endif
        let frameSizes = [Resolution.fullHD, .ultraHD]
        var benchmarks: [Benchmark] = []
        for renderer in renderers {
            for size in frameSizes {
                for level in [0, 4, 6] {
                    benchmarks.append(.frame(renderer: renderer, size: size, subdivisionLevel: level))
                }
            }
        }
        for renderer in renderers {
            for size in frameSizes {
                benchmarks.append(.throughput(renderer: renderer, size: size, subdivisionLevel: 6))
            }
        }
        for level in [4, 6] {
            benchmarks.append(.globeBuild(subdivisionLevel: level))
        }
        for size in [Resolution.fullHD, .ultraHD, .eightK] {
            benchmarks.append(.renderTargetMemory(renderer: renderers.last!, size: size))
        }
        return benchmarks
    }

    // MARK: - Recording

    /// Attaches the launch's results to the test, and writes them to `MIR_BENCH_OUTPUT_DIR` if set.
    private func record(_ launch: LaunchResult, settings: BenchmarkSettings) throws {
        let data = try JSONEncoder.benchmarkResults.encode(launch)
        let name = "mir-bench-\(settings.commit ?? "local")-\(settings.launchIndex ?? 0).json"
        Attachment.record(data, named: name)
        if let directory = settings.outputDirectory {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appending(path: name))
        }
    }

    private func summary(of result: BenchmarkResult) -> String {
        let values = result.metrics.map { metric in
            let value = median(metric.samples)
            let isWhole = value >= 1_000 || value == value.rounded()
            let formatted = isWhole ? String(format: "%.0f", value) : String(format: "%.3f", value)
            return "\(metric.name) \(formatted) \(metric.unit)"
        }
        return "\(result.name): " + values.joined(separator: ", ")
    }

    /// Waits up to 60 seconds for the machine to cool down to the nominal thermal state.
    private func waitForNominalThermalState() {
        let deadline = Date().addingTimeInterval(60)
        while ProcessInfo.processInfo.thermalState != .nominal, Date() < deadline {
            Thread.sleep(forTimeInterval: 5)
        }
    }
}

// MARK: - Settings

/// What to run and where to put the results, from environment variables the runner script sets.
struct BenchmarkSettings {

    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["MIR_BENCH"] == "1"
    }

    static var current: BenchmarkSettings {
        let environment = ProcessInfo.processInfo.environment
        func value(_ name: String) -> String? {
            guard let value = environment[name], !value.isEmpty else { return nil }
            return value
        }
        return BenchmarkSettings(
            filter: value("MIR_BENCH_FILTER"),
            warmupFrames: value("MIR_BENCH_WARMUP").flatMap(Int.init) ?? 10,
            sampleFrames: value("MIR_BENCH_FRAMES").flatMap(Int.init) ?? 60,
            outputDirectory: value("MIR_BENCH_OUTPUT_DIR").map { URL(filePath: $0, directoryHint: .isDirectory) },
            commit: value("MIR_BENCH_COMMIT"),
            launchIndex: value("MIR_BENCH_LAUNCH").flatMap(Int.init)
        )
    }

    /// Only benchmarks whose name contains this text run.
    var filter: String?
    var warmupFrames: Int
    var sampleFrames: Int
    var outputDirectory: URL?
    var commit: String?
    var launchIndex: Int?

    func includes(_ name: String) -> Bool {
        guard let filter else { return true }
        return name.contains(filter)
    }
}

// MARK: - Benchmarks

struct Resolution {
    static let fullHD = Resolution(name: "1080p", width: 1920, height: 1080)
    static let ultraHD = Resolution(name: "4k", width: 3840, height: 2160)
    static let eightK = Resolution(name: "8k", width: 7680, height: 4320)

    let name: String
    let width: Int
    let height: Int
}

/// A named, parameterized measurement.
struct Benchmark {

    let name: String
    let parameters: [String: String]
    let run: @MainActor (MTLDevice, BenchmarkSettings) throws -> [Metric]

    /// Renders frames one at a time and measures each: CPU encode time, GPU time and total time,
    /// plus the frame's work counters and, where available, CPU instructions and energy per frame.
    static func frame(renderer: String, size: Resolution, subdivisionLevel: Int) -> Benchmark {
        Benchmark(
            name: "frame/\(renderer)/\(size.name)/level\(subdivisionLevel)",
            parameters: [
                "renderer": renderer,
                "width": "\(size.width)",
                "height": "\(size.height)",
                "subdivisionLevel": "\(subdivisionLevel)"
            ]
        ) { device, settings in
            var scene = Scene()
            scene.globe = Globe(subdivisionLevel: subdivisionLevel)
            scene.camera.aspectRatio = Double(size.width) / Double(size.height)
            let frameRenderer = try makeRenderer(named: renderer, device: device, scene: scene)
            try frameRenderer.compileRenderPipeline(colorPixelFormat: .bgra8Unorm)
            let target = try OffscreenTarget(device: device, width: size.width, height: size.height)
            for _ in 0..<settings.warmupFrames {
                try frameRenderer.renderFrame(into: target.texture)
            }
            var encode: [Double] = []
            var gpu: [Double] = []
            var total: [Double] = []
            let before = ProcessCounters.current()
            for _ in 0..<settings.sampleFrames {
                let timing = try frameRenderer.renderFrame(into: target.texture)
                encode.append(timing.encodeSeconds * 1_000)
                gpu.append(timing.gpuSeconds * 1_000)
                total.append(timing.totalSeconds * 1_000)
            }
            let increase = ProcessCounters.current().increase(since: before, per: settings.sampleFrames)
            let statistics = frameRenderer.lastFrameStatistics
            var metrics = [
                Metric(name: "draw calls", unit: "count", tier: .workCounter, samples: [Double(statistics.drawCalls)]),
                Metric(name: "uploaded", unit: "bytes", tier: .workCounter, samples: [Double(statistics.uploadedBytes)]),
                Metric(name: "encode", unit: "ms", tier: .measured, samples: encode),
                Metric(name: "gpu", unit: "ms", tier: .measured, samples: gpu),
                Metric(name: "total", unit: "ms", tier: .measured, samples: total)
            ]
            if let instructions = increase.instructions {
                metrics.append(Metric(name: "instructions", unit: "per frame", tier: .cpuCounter, samples: [instructions]))
            }
            if let cycles = increase.cycles {
                metrics.append(Metric(name: "cycles", unit: "per frame", tier: .cpuCounter, samples: [cycles]))
            }
            if let energy = increase.energyNanojoules {
                metrics.append(Metric(name: "energy", unit: "µJ per frame", tier: .measured, samples: [energy / 1_000]))
            }
            return metrics
        }
    }

    /// Renders frames back to back, as an export does, and reports the average time per frame.
    ///
    /// Unlike the frame benchmarks, the CPU encodes later frames while the GPU runs earlier ones
    /// (up to three in flight), so this measures throughput rather than one frame's latency.
    /// Each of five batches of frames gives one sample.
    static func throughput(renderer: String, size: Resolution, subdivisionLevel: Int) -> Benchmark {
        Benchmark(
            name: "throughput/\(renderer)/\(size.name)/level\(subdivisionLevel)",
            parameters: [
                "renderer": renderer,
                "width": "\(size.width)",
                "height": "\(size.height)",
                "subdivisionLevel": "\(subdivisionLevel)"
            ]
        ) { device, settings in
            var scene = Scene()
            scene.globe = Globe(subdivisionLevel: subdivisionLevel)
            scene.camera.aspectRatio = Double(size.width) / Double(size.height)
            let frameRenderer = try makeRenderer(named: renderer, device: device, scene: scene)
            try frameRenderer.compileRenderPipeline(colorPixelFormat: .bgra8Unorm)
            let targets = try (0..<3).map { _ in
                try OffscreenTarget(device: device, width: size.width, height: size.height).texture
            }
            try frameRenderer.renderFrames(settings.warmupFrames, into: targets)
            let batches = 5
            var perFrame: [Double] = []
            let before = ProcessCounters.current()
            for _ in 0..<batches {
                let seconds = try frameRenderer.renderFrames(settings.sampleFrames, into: targets)
                perFrame.append(seconds / Double(settings.sampleFrames) * 1_000)
            }
            let increase = ProcessCounters.current().increase(since: before, per: batches * settings.sampleFrames)
            var metrics = [Metric(name: "frame time", unit: "ms", tier: .measured, samples: perFrame)]
            if let instructions = increase.instructions {
                metrics.append(Metric(name: "instructions", unit: "per frame", tier: .cpuCounter, samples: [instructions]))
            }
            if let energy = increase.energyNanojoules {
                metrics.append(Metric(name: "energy", unit: "µJ per frame", tier: .measured, samples: [energy / 1_000]))
            }
            return metrics
        }
    }

    /// Builds the globe mesh, which the renderers do whenever the level of detail changes.
    static func globeBuild(subdivisionLevel: Int) -> Benchmark {
        Benchmark(
            name: "globe-build/level\(subdivisionLevel)",
            parameters: ["subdivisionLevel": "\(subdivisionLevel)"]
        ) { _, _ in
            let clock = ContinuousClock()
            let builds = 10
            _ = Globe(subdivisionLevel: subdivisionLevel)
            var times: [Double] = []
            let before = ProcessCounters.current()
            for _ in 0..<builds {
                let start = clock.now
                let globe = Globe(subdivisionLevel: subdivisionLevel)
                times.append((clock.now - start).inSeconds * 1_000)
                precondition(!globe.patches.isEmpty)
            }
            let increase = ProcessCounters.current().increase(since: before, per: builds)
            var metrics = [Metric(name: "build", unit: "ms", tier: .measured, samples: times)]
            if let instructions = increase.instructions {
                metrics.append(Metric(name: "instructions", unit: "per build", tier: .cpuCounter, samples: [instructions]))
            }
            return metrics
        }
    }

    /// Measures the GPU memory a render target of a given size adds, and the process footprint.
    static func renderTargetMemory(renderer: String, size: Resolution) -> Benchmark {
        Benchmark(
            name: "memory/\(renderer)/\(size.name)",
            parameters: ["renderer": renderer, "width": "\(size.width)", "height": "\(size.height)"]
        ) { device, _ in
            var scene = Scene()
            scene.camera.aspectRatio = Double(size.width) / Double(size.height)
            let frameRenderer = try makeRenderer(named: renderer, device: device, scene: scene)
            try frameRenderer.compileRenderPipeline(colorPixelFormat: .bgra8Unorm)
            let gpuBefore = device.currentAllocatedSize
            let footprintBefore = ProcessCounters.current().footprintBytes
            let target = try OffscreenTarget(device: device, width: size.width, height: size.height)
            try frameRenderer.renderFrame(into: target.texture)
            let gpuAfter = device.currentAllocatedSize
            let footprintAfter = ProcessCounters.current().footprintBytes
            return [
                Metric(name: "gpu memory", unit: "bytes", tier: .workCounter, samples: [Double(gpuAfter) - Double(gpuBefore)]),
                Metric(name: "footprint", unit: "bytes", tier: .measured, samples: [Double(footprintAfter) - Double(footprintBefore)])
            ]
        }
    }
}

@MainActor
private func makeRenderer(named name: String, device: MTLDevice, scene: Scene) throws -> any Renderer {
    switch name {
    case "metal":
        return MapMetalRenderer(device: device, scene: scene)
    #if !targetEnvironment(simulator)
    case "metal4":
        return try MapMetal4Renderer(device: device, scene: scene)
    #endif
    default:
        throw RendererError.encodingUnavailable
    }
}
