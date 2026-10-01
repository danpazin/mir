// WorkBudgetTests.swift
// MirTests
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation
import Metal
import Mir
import Testing

/// Holds each renderer's per-frame work to the budgets in `Resources/budgets.json`.
///
/// Draw calls and uploaded bytes are exact counts, so unlike timings they can gate every
/// change on any machine: a change that adds work fails here before anyone measures a frame.
@MainActor
@Suite("Work budgets")
struct WorkBudgetTests {

    struct Budget: Decodable, Sendable, CustomTestStringConvertible {
        let renderer: String
        let subdivisionLevel: Int
        let maxDrawCalls: Int
        let maxUploadedBytes: Int

        var testDescription: String { "\(renderer), subdivision level \(subdivisionLevel)" }
    }

    private struct BudgetFile: Decodable {
        let frames: [Budget]
    }

    nonisolated static let budgets: [Budget] = {
        guard
            let url = Bundle.module.url(forResource: "budgets", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(BudgetFile.self, from: data)
        else {
            return []
        }
        #if targetEnvironment(simulator)
        return file.frames.filter { $0.renderer != "metal4" }
        #else
        let supportsMetal4 = MTLCreateSystemDefaultDevice()?.supportsFamily(.metal4) ?? false
        return file.frames.filter { $0.renderer != "metal4" || supportsMetal4 }
        #endif
    }()

    @Test("The budget file loads")
    func budgetFileLoads() {
        #expect(!Self.budgets.isEmpty)
    }

    @Test("Each frame stays within its work budget", arguments: budgets)
    func frameStaysWithinBudget(_ budget: Budget) throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        var scene = Scene()
        scene.globe = Globe(subdivisionLevel: budget.subdivisionLevel)
        let renderer = try makeRenderer(named: budget.renderer, device: device, scene: scene)
        try renderer.compileRenderPipeline(colorPixelFormat: .bgra8Unorm)
        let target = try OffscreenTarget(device: device, width: 64, height: 64)
        // The first frame can include one-time uploads; budgets hold for every frame after it.
        try renderer.renderFrame(into: target.texture)
        try renderer.renderFrame(into: target.texture)
        let statistics = renderer.lastFrameStatistics
        #expect(
            statistics.drawCalls <= budget.maxDrawCalls,
            "\(statistics.drawCalls) draw calls; the budget is \(budget.maxDrawCalls)"
        )
        #expect(
            statistics.uploadedBytes <= budget.maxUploadedBytes,
            "\(statistics.uploadedBytes) bytes uploaded; the budget is \(budget.maxUploadedBytes)"
        )
    }

    private func makeRenderer(named name: String, device: MTLDevice, scene: Scene) throws -> any Renderer {
        switch name {
        case "metal":
            return MapMetalRenderer(device: device, scene: scene)
        #if !targetEnvironment(simulator)
        case "metal4":
            return try MapMetal4Renderer(device: device, scene: scene)
        #endif
        default:
            Issue.record("Unknown renderer \"\(name)\" in budgets.json")
            throw RendererError.encodingUnavailable
        }
    }
}
