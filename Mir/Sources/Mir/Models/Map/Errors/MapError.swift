// MapError.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation

struct MapError: LocalizedError {
    
    enum Kind {
        /// The required Metal device could not be obtained (e.g. `MTLCreateSystemDefaultDevice()` returned nil).
        case deviceUnavailable
        /// The renderer could not be created or initialized.
        case rendererUnavailable
    }
    
    // MARK: - Properties
    
    let kind: Kind
    let underlyingError: Error?
    
    // MARK: - Initializers
    
    init(kind: Kind) {
        self.kind = kind
        self.underlyingError = nil
    }
    
    init(kind: Kind, underlyingError: Error) {
        self.kind = kind
        self.underlyingError = underlyingError
    }
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        switch kind {
        case .deviceUnavailable:
            return "Metal is not available on this device."
        case .rendererUnavailable:
            return "The renderer could not be created."
        }
    }
}
