#!/bin/bash
# bench.sh
# Mir
#
# SPDX-License-Identifier: Apache-2.0
# Copyright © 2026 Daniil Pazin. All rights reserved.
#
# Builds the benchmarks once in Release, then runs them in several separate launches.
# Each launch writes one JSON file. Separate processes matter: some noise (memory layout,
# caches, scheduling) only shows up between launches, so each launch counts as one sample.
#
# Usage: scripts/bench.sh [--launches N] [--out DIR] [--filter TEXT] [--frames N] [--derived DIR]

set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
launches=5
out=""
filter=""
frames=""
derived="$repo/build/derived-release"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --launches) launches="$2"; shift 2 ;;
        --out) out="$2"; shift 2 ;;
        --filter) filter="$2"; shift 2 ;;
        --frames) frames="$2"; shift 2 ;;
        --derived) derived="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

commit="$(git -C "$repo" rev-parse --short HEAD)"
out="${out:-$repo/build/bench/$commit}"
mkdir -p "$out"
out="$(cd "$out" && pwd)"

echo "Building benchmarks for $commit (Release)..."
(cd "$repo/Mir" && xcodebuild build-for-testing \
    -scheme Mir \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "$derived" \
    > "$out/build.log" 2>&1) || { tail -30 "$out/build.log"; exit 1; }

for launch in $(seq 1 "$launches"); do
    echo "Launch $launch of $launches"
    rm -rf "$out/launch-$launch.xcresult"
    (cd "$repo/Mir" && \
        TEST_RUNNER_MIR_BENCH=1 \
        TEST_RUNNER_MIR_BENCH_COMMIT="$commit" \
        TEST_RUNNER_MIR_BENCH_LAUNCH="$launch" \
        TEST_RUNNER_MIR_BENCH_OUTPUT_DIR="$out" \
        TEST_RUNNER_MIR_BENCH_FILTER="$filter" \
        TEST_RUNNER_MIR_BENCH_FRAMES="$frames" \
        xcodebuild test-without-building \
            -scheme Mir \
            -configuration Release \
            -destination 'platform=macOS' \
            -derivedDataPath "$derived" \
            -only-testing:MirBenchmarks \
            -resultBundlePath "$out/launch-$launch.xcresult" \
            > "$out/launch-$launch.log" 2>&1) || { tail -30 "$out/launch-$launch.log"; exit 1; }
    grep '\[mir-bench\]' "$out/launch-$launch.log" | sed 's/^.*\[mir-bench\] /  /' | sort -u
done

echo "Results: $out"
