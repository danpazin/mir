// RenderedImage.swift
// MirTests
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

/// The pixels of a rendered frame, with helpers for checking what the frame shows.
struct RenderedImage {

    /// An 8-bit color, with channels from 0 to 255.
    struct Color: CustomStringConvertible {

        static let black = Color(red: 0, green: 0, blue: 0)

        var red: Double
        var green: Double
        var blue: Double

        var description: String {
            "RGB(\(Int(red.rounded())), \(Int(green.rounded())), \(Int(blue.rounded())))"
        }

        /// The largest difference between any two matching channels.
        func distance(to other: Color) -> Double {
            max(abs(red - other.red), abs(green - other.green), abs(blue - other.blue))
        }
    }

    // MARK: - Properties

    let width: Int
    let height: Int
    /// 4 bytes per pixel in blue, green, red, alpha order, as `MTLPixelFormat.bgra8Unorm` stores them.
    let bytes: [UInt8]

    // MARK: - Reading Colors

    /// The color of one pixel, counted from the top-left corner.
    func color(atX x: Int, y: Int) -> Color {
        let index = (y * width + x) * 4
        return Color(red: Double(bytes[index + 2]), green: Double(bytes[index + 1]), blue: Double(bytes[index]))
    }

    /// The average color of the square of pixels centred on a point.
    ///
    /// Averaging smooths over the edges between triangles, so a check doesn't depend on which
    /// triangle covers one exact pixel.
    func averageColor(aroundX centerX: Int, y centerY: Int, radius: Int) -> Color {
        var sum = Color.black
        var count = 0.0
        for y in (centerY - radius)...(centerY + radius) {
            for x in (centerX - radius)...(centerX + radius) {
                let color = color(atX: x, y: y)
                sum.red += color.red
                sum.green += color.green
                sum.blue += color.blue
                count += 1
            }
        }
        return Color(red: sum.red / count, green: sum.green / count, blue: sum.blue / count)
    }

    /// The fraction of pixels whose color differs from the background.
    func coverage(excluding background: Color) -> Double {
        var covered = 0
        for y in 0..<height {
            for x in 0..<width where color(atX: x, y: y).distance(to: background) > 0 {
                covered += 1
            }
        }
        return Double(covered) / Double(width * height)
    }

    /// Compares two images of the same size.
    ///
    /// - Returns: The largest difference in any channel, and the fraction of pixels that differ at all.
    func difference(from other: RenderedImage) -> (maxChannelDelta: Int, differingFraction: Double) {
        precondition(width == other.width && height == other.height, "Images must be the same size")
        var maxChannelDelta = 0
        var differingPixels = 0
        for pixel in 0..<(width * height) {
            var pixelDelta = 0
            for channel in 0..<3 {
                let index = pixel * 4 + channel
                pixelDelta = max(pixelDelta, abs(Int(bytes[index]) - Int(other.bytes[index])))
            }
            maxChannelDelta = max(maxChannelDelta, pixelDelta)
            if pixelDelta > 0 {
                differingPixels += 1
            }
        }
        return (maxChannelDelta, Double(differingPixels) / Double(width * height))
    }

    // MARK: - Saving

    /// Encodes the image as PNG.
    func pngData() -> Data? {
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        guard
            let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
            let provider = CGDataProvider(data: Data(bytes) as CFData),
            let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
            )
        else {
            return nil
        }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }

    /// Attaches the image to the current test as a PNG.
    ///
    /// When `MIR_TEST_OUTPUT_DIR` is set (pass `TEST_RUNNER_MIR_TEST_OUTPUT_DIR` to `xcodebuild`),
    /// the PNG is also written to that directory, so the images can be opened without the result bundle.
    func record(named name: String) {
        guard let data = pngData() else { return }
        Attachment.record(data, named: "\(name).png")
        if let path = ProcessInfo.processInfo.environment["MIR_TEST_OUTPUT_DIR"] {
            let directory = URL(filePath: path, directoryHint: .isDirectory)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try? data.write(to: directory.appending(path: "\(name).png"))
        }
    }
}
