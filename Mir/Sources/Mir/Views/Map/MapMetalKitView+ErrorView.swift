// MapMetalKitView+ErrorView.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import MetalKit

extension MapMetalKitView {
    
    static func makeErrorMTKView(message: String) -> MTKView {
        let view = MTKView()
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        let errorView = MapErrorView()
        errorView.configure(message: message)
        view.addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        let inset: CGFloat = 16.0
        NSLayoutConstraint.activate([
            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 1, constant: -inset),
            errorView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 1, constant: -inset)
        ])
        return view
    }
}
