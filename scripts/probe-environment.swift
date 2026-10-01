// probe-environment.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//
// Prints what this machine offers for benchmarking: hardware, OS, GPU, and whether the
// per-process CPU and energy counters work. CI runs it first, so every job log says which
// machine produced its numbers.
//
// Usage: swift scripts/probe-environment.swift

import Darwin
import Foundation
import Metal

func sysctlString(_ name: String) -> String {
    var size = 0
    guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return "unavailable" }
    var value = [CChar](repeating: 0, count: size)
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return "unavailable" }
    return String(cString: value)
}

func sysctlInt(_ name: String) -> Int? {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
    return Int(value)
}

func rusage() -> rusage_info_v6? {
    var info = rusage_info_v6()
    let result = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
            proc_pid_rusage(getpid(), RUSAGE_INFO_V6, $0)
        }
    }
    return result == 0 ? info : nil
}

let process = ProcessInfo.processInfo
print("== Machine")
print("model:              \(sysctlString("hw.model"))")
print("cpu:                \(sysctlString("machdep.cpu.brand_string"))")
print("virtual machine:    \(sysctlInt("kern.hv_vmm_present") == 1 ? "yes" : "no")")
print("cores (P/E):        \(sysctlInt("hw.perflevel0.physicalcpu") ?? 0)/\(sysctlInt("hw.perflevel1.physicalcpu") ?? 0)")
print("memory:             \(process.physicalMemory / 1_073_741_824) GB")
print("os:                 \(process.operatingSystemVersionString)")

print("\n== Conditions")
let thermal = ["nominal", "fair", "serious", "critical"][process.thermalState.rawValue]
print("thermal state:      \(thermal)")
print("low power mode:     \(process.isLowPowerModeEnabled ? "on" : "off")")

print("\n== GPU")
if let device = MTLCreateSystemDefaultDevice() {
    print("name:               \(device.name)")
    print("metal 4:            \(device.supportsFamily(.metal4) ? "yes" : "no")")
    let appleFamily = (1...10).last { device.supportsFamily(MTLGPUFamily(rawValue: 1000 + $0)!) } ?? 0
    print("apple family:       \(appleFamily)")
    print("unified memory:     \(device.hasUnifiedMemory ? "yes" : "no")")
    print("working set limit:  \(device.recommendedMaxWorkingSetSize / 1_048_576) MB")
} else {
    print("no Metal device")
}

print("\n== Counters (a ~50 ms busy loop)")
if let before = rusage() {
    var x = 0.0
    let start = Date()
    while Date().timeIntervalSince(start) < 0.05 {
        for i in 0..<10_000 { x += sin(Double(i)) }
    }
    if let after = rusage() {
        let instructions = after.ri_instructions - before.ri_instructions
        let cycles = after.ri_cycles - before.ri_cycles
        let energy = after.ri_energy_nj - before.ri_energy_nj
        print("instructions:       \(instructions)\(instructions == 0 ? "  (unavailable)" : "")")
        print("cycles:             \(cycles)\(cycles == 0 ? "  (unavailable)" : "")")
        print("energy:             \(energy) nJ\(energy == 0 ? "  (unavailable)" : "")")
        print("footprint:          \(after.ri_phys_footprint / 1_048_576) MB")
    }
    _ = x
} else {
    print("proc_pid_rusage failed")
}
