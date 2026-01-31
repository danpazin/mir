// MapMetal4Renderer+Setup.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Metal

extension MapMetal4Renderer {

    // MARK: - Make Long-Term Resources

    /// Makes a Metal 4 argument table for managing buffer resources.
    ///
    /// This function configures and makes an argument table that can hold a specified
    /// number of buffer bindings. The argument table is used to manage resources
    /// that will be passed to the GPU.
    ///
    /// - Returns: A configured `MTL4ArgumentTable` instance.
    /// - Throws: An error if the argument table cannot be made from the Metal device.
    func makeArgumentTable() throws -> some MTL4ArgumentTable {
        let argumentTableDescriptor = MTL4ArgumentTableDescriptor()
        argumentTableDescriptor.maxBufferBindCount = 1
        let argumentTable = try device.makeArgumentTable(descriptor: argumentTableDescriptor)
        return argumentTable
    }

    /// Makes a residency set for managing resource memory.
    ///
    /// This function makes a residency set, which is used to manage the memory
    /// residency of resources, ensuring that they are available to the GPU when needed.
    ///
    /// - Returns: A configured `MTLResidencySet` instance.
    /// - Throws: An error if the residency set cannot be made from the Metal device.
    func makeResidencySet() throws -> some MTLResidencySet {
        let residencySetDescriptor = MTLResidencySetDescriptor()
        let residencySet = try device.makeResidencySet(descriptor: residencySetDescriptor)
        return residencySet
    }
}
