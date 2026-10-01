// Measure.swift
// MirBenchmarks
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Darwin
import Foundation

/// Counters the OS keeps for this process.
///
/// Instructions, cycles and energy come from `proc_pid_rusage`, which only macOS offers. They
/// count every thread in the process, including Metal's, so they cover the whole cost of a frame.
/// In a virtual machine they read zero, so a zero difference means "unavailable".
struct ProcessCounters {

    var instructions: UInt64?
    var cycles: UInt64?
    var energyNanojoules: UInt64?
    /// The memory footprint the OS charges this process for, in bytes.
    var footprintBytes: UInt64

    static func current() -> ProcessCounters {
        #if os(macOS)
        var info = rusage_info_v6()
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                proc_pid_rusage(getpid(), RUSAGE_INFO_V6, $0)
            }
        }
        if result == 0 {
            return ProcessCounters(
                instructions: info.ri_instructions,
                cycles: info.ri_cycles,
                energyNanojoules: info.ri_energy_nj,
                footprintBytes: info.ri_phys_footprint
            )
        }
        #endif
        return ProcessCounters(instructions: nil, cycles: nil, energyNanojoules: nil, footprintBytes: taskFootprint())
    }

    /// The difference in each counter since an earlier reading, divided by a number of operations.
    ///
    /// - Returns: The per-operation increase for each available counter.
    func increase(since earlier: ProcessCounters, per operations: Int) -> (instructions: Double?, cycles: Double?, energyNanojoules: Double?) {
        func perOperation(_ now: UInt64?, _ then: UInt64?) -> Double? {
            guard let now, let then, now > then else { return nil }
            return Double(now - then) / Double(operations)
        }
        return (
            perOperation(instructions, earlier.instructions),
            perOperation(cycles, earlier.cycles),
            perOperation(energyNanojoules, earlier.energyNanojoules)
        )
    }
}

/// The memory footprint the OS charges this process for, from `task_info`, on any platform.
private func taskFootprint() -> UInt64 {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
    let result = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? info.phys_footprint : 0
}

/// The median of some samples, for the console summary. The analysis tool does the real statistics.
func median(_ samples: [Double]) -> Double {
    guard !samples.isEmpty else { return .nan }
    let sorted = samples.sorted()
    let middle = sorted.count / 2
    return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
}
