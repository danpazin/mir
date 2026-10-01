// CommitFeedback.swift
// Mir
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

#if !targetEnvironment(simulator)

import Dispatch
import Metal
import Synchronization

/// Collects the GPU's report on a committed command buffer, which Metal delivers on its own thread.
final class CommitFeedback: Sendable {

    /// What the GPU reported about the work it ran.
    struct Report: Sendable {
        /// GPU time from the GPU's own start and end timestamps, in seconds.
        let gpuSeconds: Double
        /// A description of the error the GPU hit, if any.
        let error: String?
    }

    // MARK: - Properties

    private let report = Mutex<Report?>(nil)
    private let delivered = DispatchSemaphore(value: 0)

    // MARK: - Reporting

    /// Stores Metal's feedback. Metal calls this once the GPU finishes the committed work.
    func record(_ feedback: any MTL4CommitFeedback) {
        let report = Report(
            gpuSeconds: feedback.gpuEndTime - feedback.gpuStartTime,
            error: feedback.error?.localizedDescription
        )
        self.report.withLock { $0 = report }
        delivered.signal()
    }

    /// Waits for the GPU's report.
    ///
    /// - Parameter timeoutSeconds: How long to wait before giving up.
    /// - Returns: The report, or `nil` if it didn't arrive in time.
    func wait(timeoutSeconds: Double) -> Report? {
        guard delivered.wait(timeout: .now() + timeoutSeconds) == .success else { return nil }
        return report.withLock { $0 }
    }
}

#endif
