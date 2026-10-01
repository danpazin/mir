// RenderTests.swift
// MirTests
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Metal
import Mir
import Testing

/// Checks what the renderers actually draw, by rendering the default scene into an offscreen image.
@MainActor
@Suite("Rendering")
struct RenderTests {

    /// The size of the square offscreen image, in pixels.
    static let size = 512

    /// The color of the globe at the centre of the default view.
    ///
    /// The default camera looks straight at latitude 0, longitude 0, where the surface normal is
    /// (1, 0, 0). With the light along (1, 1, 1), diffuse = 1/√3 ≈ 0.577, so the shader's intensity
    /// is 0.15 + 0.577 and its base color (0.2, 0.6, 0.3) becomes about RGB(37, 111, 56).
    /// The far side, seen from inside, would be about RGB(8, 23, 11).
    static let litCentre = RenderedImage.Color(red: 37, green: 111, blue: 56)

    // MARK: - Tests

    @Test("The Metal renderer shows the lit near side of the globe")
    func metalRendererShowsLitNearSide() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let image = try render(with: MapMetalRenderer(device: device), on: device)
        image.record(named: "metal-default-scene")
        try expectLitNearSide(in: image)
    }

    @Test("The whole globe fits in the default view")
    func wholeGlobeFitsInDefaultView() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let image = try render(with: MapMetalRenderer(device: device), on: device)
        #expect(image.edgePixelCount(excluding: .black) == 0, "The globe touches the edge of the frame")
    }

    #if !targetEnvironment(simulator)
    nonisolated static let supportsMetal4 = MTLCreateSystemDefaultDevice()?.supportsFamily(.metal4) ?? false

    @Test("The Metal 4 renderer shows the lit near side of the globe", .enabled(if: supportsMetal4))
    func metal4RendererShowsLitNearSide() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let image = try render(with: MapMetal4Renderer(device: device), on: device)
        image.record(named: "metal4-default-scene")
        try expectLitNearSide(in: image)
    }

    /// The Metal 4 renderer uploads the globe only when it changes, so a stale upload would draw
    /// the old globe, or overrun the vertex buffer.
    @Test("The Metal 4 renderer re-uploads the globe when its level changes", .enabled(if: supportsMetal4))
    func metal4ReuploadsChangedGlobe() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let renderer = try MapMetal4Renderer(device: device)
        try renderer.compileRenderPipeline(colorPixelFormat: .bgra8Unorm)
        renderer.scene.camera.aspectRatio = 1
        let target = try OffscreenTarget(device: device, width: Self.size, height: Self.size)
        try renderer.renderFrame(into: target.texture)
        renderer.scene.globe = Globe(subdivisionLevel: 2)
        try renderer.renderFrame(into: target.texture)
        // Uniforms are three 4×4 float matrices (192 bytes); vertices are 16-byte float3s.
        let expectedBytes = 192 + renderer.scene.globe.patches.count * 3 * MemoryLayout<SIMD3<Float>>.stride
        #expect(renderer.lastFrameStatistics.uploadedBytes == expectedBytes)
        let image = RenderedImage(width: target.width, height: target.height, bytes: target.pixelBytes())
        try expectLitNearSide(in: image)
    }

    @Test("Both renderers draw the same image", .enabled(if: supportsMetal4))
    func renderersDrawTheSameImage() throws {
        let device = try #require(MTLCreateSystemDefaultDevice())
        let metal = try render(with: MapMetalRenderer(device: device), on: device)
        let metal4 = try render(with: MapMetal4Renderer(device: device), on: device)
        let difference = metal.difference(from: metal4)
        #expect(difference.maxChannelDelta <= 2, "Channels differ by up to \(difference.maxChannelDelta)")
        #expect(difference.differingFraction <= 0.001, "\(difference.differingFraction * 100)% of pixels differ")
    }
    #endif

    // MARK: - Helpers

    /// Renders the default scene into a square offscreen image.
    private func render(with renderer: some Renderer, on device: MTLDevice) throws -> RenderedImage {
        try renderer.compileRenderPipeline(colorPixelFormat: .bgra8Unorm)
        renderer.scene.camera.aspectRatio = 1
        let target = try OffscreenTarget(device: device, width: Self.size, height: Self.size)
        try renderer.renderFrame(into: target.texture)
        return RenderedImage(width: target.width, height: target.height, bytes: target.pixelBytes())
    }

    private func expectLitNearSide(in image: RenderedImage) throws {
        let coverage = image.coverage(excluding: .black)
        try #require(coverage > 0.2, "Only \(Int(coverage * 100))% of the frame is drawn")
        let centre = image.averageColor(aroundX: Self.size / 2, y: Self.size / 2, radius: 2)
        #expect(
            centre.distance(to: Self.litCentre) <= 4,
            "The centre is \(centre); the lit near side is about \(Self.litCentre)"
        )
    }
}
