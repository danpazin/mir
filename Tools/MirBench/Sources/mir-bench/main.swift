// main.swift
// mir-bench
//
// SPDX-License-Identifier: Apache-2.0
// Copyright © 2026 Daniil Pazin. All rights reserved.
//

import Foundation
import MirBenchKit

let usage = """
    Usage:
      mir-bench compare --base DIR --head DIR [--thresholds FILE] [--markdown FILE]
          Compares two runs of scripts/bench.sh and prints a Markdown report.
          Exits with 1 if any metric regressed. --markdown also appends the report to FILE,
          for example $GITHUB_STEP_SUMMARY.

      mir-bench summary DIR
          Shows each metric's median and how much it varies between launches and between frames.
    """

func option(_ name: String, in arguments: [String]) -> String? {
    guard let index = arguments.firstIndex(of: name), index + 1 < arguments.count else { return nil }
    return arguments[index + 1]
}

func append(_ text: String, toFile path: String) throws {
    let url = URL(filePath: path)
    if !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil)
    }
    let handle = try FileHandle(forWritingTo: url)
    defer { try? handle.close() }
    try handle.seekToEnd()
    try handle.write(contentsOf: Data((text + "\n").utf8))
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("mir-bench: \(message)\n".utf8))
    exit(2)
}

let arguments = Array(CommandLine.arguments.dropFirst())
do {
    switch arguments.first {
    case "compare":
        guard let base = option("--base", in: arguments), let head = option("--head", in: arguments) else {
            fail("compare needs --base and --head\n\n\(usage)")
        }
        let thresholds = try option("--thresholds", in: arguments).map { try Thresholds.load(from: URL(filePath: $0)) } ?? .standard
        let report = try compare(
            base: LaunchResult.load(from: URL(filePath: base, directoryHint: .isDirectory)),
            head: LaunchResult.load(from: URL(filePath: head, directoryHint: .isDirectory)),
            thresholds: thresholds
        )
        let markdown = report.markdown()
        print(markdown)
        if let path = option("--markdown", in: arguments) {
            try append(markdown, toFile: path)
        }
        exit(report.regressions.isEmpty ? 0 : 1)
    case "summary":
        guard arguments.count >= 2 else { fail("summary needs a results directory\n\n\(usage)") }
        let launches = try LaunchResult.load(from: URL(filePath: arguments[1], directoryHint: .isDirectory))
        print(summarizeNoise(launches).text())
    default:
        print(usage)
        exit(arguments.isEmpty ? 0 : 2)
    }
} catch {
    fail("\(error)")
}
