// MapMetal4Renderer+Setup.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Metal

extension MapMetal4Renderer {

    // MARK: - Make Long-Term Resources

    /// Makes an argument table for binding buffer resources to the GPU.
    /// - Returns: A configured `MTL4ArgumentTable` instance.
    /// - Throws: An error if the Metal device cannot make the argument table.
    func makeArgumentTable() throws -> some MTL4ArgumentTable {
        let argumentTableDescriptor = MTL4ArgumentTableDescriptor()
        argumentTableDescriptor.maxBufferBindCount = 2
        let argumentTable = try device.makeArgumentTable(descriptor: argumentTableDescriptor)
        return argumentTable
    }

    /// Makes a residency set for managing long-lived resource memory.
    /// - Returns: A configured `MTLResidencySet` instance.
    /// - Throws: An error if the Metal device cannot make the residency set.
    func makeResidencySet() throws -> some MTLResidencySet {
        let residencySetDescriptor = MTLResidencySetDescriptor()
        let residencySet = try device.makeResidencySet(descriptor: residencySetDescriptor)
        return residencySet
    }

    /// Sets up memory residency for the renderer's resources.
    func setUpResidency() {
        guard let residencySet,
              let commandQueue,
              let uniformBuffer,
              let globeBuffer else { return }
        residencySet.addAllocation(globeBuffer)
        residencySet.addAllocation(uniformBuffer)
        residencySet.commit()
        commandQueue.addResidencySet(residencySet)
    }
}
