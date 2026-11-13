// MapError.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

/// An error that keeps the map from drawing, with a message to show in its place.
struct MapError: LocalizedError {

    /// The ways setting up the map can fail.
    enum Kind {
        /// The required Metal device could not be obtained (e.g. `MTLCreateSystemDefaultDevice()` returned nil).
        case deviceUnavailable
        /// No renderer could be created for the device.
        case rendererUnavailable
    }

    // MARK: - Properties

    /// Which of the failures happened.
    let kind: Kind
    /// The error that caused this one, when another API reported it.
    let underlyingError: Error?

    // MARK: - Initializers

    /// Creates an error with no underlying cause.
    init(kind: Kind) {
        self.kind = kind
        self.underlyingError = nil
    }

    /// Creates an error caused by another error.
    init(kind: Kind, underlyingError: Error) {
        self.kind = kind
        self.underlyingError = underlyingError
    }

    // MARK: - LocalizedError

    /// The message shown in the map's place, followed by the underlying error's message when there is one.
    var errorDescription: String? {
        var description: String
        switch kind {
        case .deviceUnavailable:
            description = "Metal is not available on this device."
        case .rendererUnavailable:
            description = "The renderer could not be created."
        }
        if let underlyingError {
            description += "\nReason: \(underlyingError.localizedDescription)"
        }
        return description
    }
}
