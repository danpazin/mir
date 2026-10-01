// Environment.swift
// MirBenchmarks
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Darwin
import Foundation
import Metal

/// The machine and conditions a launch ran under.
struct EnvironmentInfo: Codable {
    /// The hardware model, for example `Mac16,7`.
    var model: String
    /// The machine identifier, for example `arm64` on a Mac or `iPhone18,3` on an iPhone.
    var machine: String
    var cpu: String?
    var os: String
    var gpu: String
    var supportsMetal4: Bool
    var virtualMachine: Bool
    var buildConfiguration: String
    var thermalStateAtStart: String
    var lowPowerMode: Bool
    var validationLayer: Bool
    var debuggerAttached: Bool
    var qualityOfService: String

    /// Captures the current machine and conditions.
    static func capture(device: MTLDevice) -> EnvironmentInfo {
        let process = ProcessInfo.processInfo
        #if DEBUG
        let buildConfiguration = "debug"
        #else
        let buildConfiguration = "release"
        #endif
        return EnvironmentInfo(
            model: sysctlString("hw.model") ?? "unknown",
            machine: sysctlString("hw.machine") ?? "unknown",
            cpu: sysctlString("machdep.cpu.brand_string"),
            os: process.operatingSystemVersionString,
            gpu: device.name,
            supportsMetal4: deviceSupportsMetal4(device),
            virtualMachine: sysctlInt("kern.hv_vmm_present") == 1,
            buildConfiguration: buildConfiguration,
            thermalStateAtStart: process.thermalState.name,
            lowPowerMode: process.isLowPowerModeEnabled,
            validationLayer: process.environment["MTL_DEBUG_LAYER"] == "1",
            debuggerAttached: isDebuggerAttached(),
            qualityOfService: qualityOfServiceName(qos_class_self())
        )
    }

    /// Reasons this environment would distort timings, or an empty list for a clean one.
    ///
    /// A virtual machine isn't listed: its exact work counters are still valid, and the
    /// analysis tool already ignores its timings.
    var contamination: [String] {
        var reasons: [String] = []
        if buildConfiguration != "release" {
            reasons.append("Not a Release build, so the code isn't optimized")
        }
        if validationLayer {
            reasons.append("Metal API validation is on")
        }
        if debuggerAttached {
            reasons.append("A debugger is attached")
        }
        if lowPowerMode {
            reasons.append("Low Power Mode is on")
        }
        if thermalStateAtStart != "nominal" {
            reasons.append("The thermal state was \(thermalStateAtStart) at the start")
        }
        if qualityOfService != "user-interactive" && qualityOfService != "user-initiated" {
            reasons.append("The benchmark thread ran at \(qualityOfService) quality of service")
        }
        return reasons
    }
}

extension ProcessInfo.ThermalState {

    /// The state's name as the results store it.
    var name: String {
        switch self {
        case .nominal: "nominal"
        case .fair: "fair"
        case .serious: "serious"
        case .critical: "critical"
        @unknown default: "unknown"
        }
    }
}

// MARK: - System Queries

/// Whether the device supports Metal 4. The Simulator SDK doesn't define the Metal 4 family.
private func deviceSupportsMetal4(_ device: MTLDevice) -> Bool {
    #if targetEnvironment(simulator)
    return false
    #else
    return device.supportsFamily(.metal4)
    #endif
}

private func sysctlString(_ name: String) -> String? {
    var size = 0
    guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
    var value = [CChar](repeating: 0, count: size)
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
    return String(cString: value)
}

private func sysctlInt(_ name: String) -> Int? {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return nil }
    return Int(value)
}

/// Whether a debugger is tracing this process, which slows it down.
private func isDebuggerAttached() -> Bool {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    guard sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0) == 0 else { return false }
    return info.kp_proc.p_flag & P_TRACED != 0
}

private func qualityOfServiceName(_ qos: qos_class_t) -> String {
    switch qos {
    case QOS_CLASS_USER_INTERACTIVE: "user-interactive"
    case QOS_CLASS_USER_INITIATED: "user-initiated"
    case QOS_CLASS_DEFAULT: "default"
    case QOS_CLASS_UTILITY: "utility"
    case QOS_CLASS_BACKGROUND: "background"
    default: "unspecified"
    }
}
