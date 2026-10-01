// OffscreenTarget.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Metal

/// A render target in memory instead of on screen, for tests and benchmarks.
///
/// Rendering offscreen skips the display's frame pacing, so every frame does the same work
/// under the same conditions.
package struct OffscreenTarget {

    // MARK: - Properties

    /// The texture a renderer draws into.
    package let texture: MTLTexture
    /// The width of the target, in pixels.
    package var width: Int { texture.width }
    /// The height of the target, in pixels.
    package var height: Int { texture.height }

    // MARK: - Initializers

    /// Makes an offscreen target.
    ///
    /// - Parameters:
    ///   - device: The Metal device that renders into the target.
    ///   - width: The width, in pixels.
    ///   - height: The height, in pixels.
    ///   - pixelFormat: The pixel format; the default matches `MTKView.colorPixelFormat`.
    /// - Throws: ``RendererError/textureUnavailable`` if Metal can’t make the texture.
    package init(device: MTLDevice, width: Int, height: Int, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        descriptor.storageMode = .shared
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw RendererError.textureUnavailable
        }
        self.texture = texture
    }

    // MARK: - Reading Pixels

    /// Copies the target's pixels into memory.
    ///
    /// - Returns: 4 bytes per pixel, row by row from the top, in the texture's channel order
    ///   (blue, green, red, alpha for the default pixel format).
    package func pixelBytes() -> [UInt8] {
        let bytesPerRow = width * 4
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * height)
        bytes.withUnsafeMutableBytes { buffer in
            texture.getBytes(
                buffer.baseAddress!,
                bytesPerRow: bytesPerRow,
                from: MTLRegionMake2D(0, 0, width, height),
                mipmapLevel: 0
            )
        }
        return bytes
    }
}
