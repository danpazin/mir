// MapMetal4Renderer+Setup.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Metal

// The simulators' SDKs have no Metal 4 types, so this renderer is built only for devices and Macs.
#if !targetEnvironment(simulator)
extension MapMetal4Renderer {

    // MARK: - Make Long-Term Resources

    /// Makes an argument table with room for two buffers: the vertices and the uniforms.
    func makeArgumentTable() throws -> some MTL4ArgumentTable {
        let argumentTableDescriptor = MTL4ArgumentTableDescriptor()
        argumentTableDescriptor.maxBufferBindCount = 2
        let argumentTable = try device.makeArgumentTable(descriptor: argumentTableDescriptor)
        return argumentTable
    }

    /// Makes an empty residency set.
    func makeResidencySet() throws -> some MTLResidencySet {
        let residencySetDescriptor = MTLResidencySetDescriptor()
        let residencySet = try device.makeResidencySet(descriptor: residencySetDescriptor)
        return residencySet
    }

    /// Adds both buffers to the residency set, so the GPU keeps them in memory, and attaches it to the command queue.
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
#endif
