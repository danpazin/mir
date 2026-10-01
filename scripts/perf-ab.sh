#!/bin/bash
# perf-ab.sh
# Mir
#
# SPDX-License-Identifier: Apache-2.0
# Copyright © 2026 Daniil Pazin. All rights reserved.
#
# Compares two commits on this machine: the regression gate.
#
# Builds each commit once, in its own git worktree with its own derived data (so builds are
# cached per commit), then runs the benchmark launches interleaved: A, B, B, A, A, B, ...
# Slow drift (heat, background work) then hits both sides equally. Finally mir-bench compares
# the two sides and exits 1 if any metric regressed.
#
# Usage: scripts/perf-ab.sh [--base REF] [--head REF] [--launches N] [--out DIR]
#                           [--filter TEXT] [--frames N] [--report FILE] [--repo DIR] [--tools REF]
#   --base     the commit to compare against (default HEAD~1)
#   --head     the commit under test (default HEAD)
#   --launches launches per side (default 5; with 5 vs 5 the smallest p-value is 1/252)
#   --report   also append the Markdown report to FILE, for example $GITHUB_STEP_SUMMARY
#   --repo     the repository, when this script runs from a copy outside it (default: its parent)
#   --tools    a commit whose Tools/MirBench and thresholds to use (default: the working copy),
#              so a bisection judges every step with the same rules
#
# Exit codes: 0 no regression, 1 regression, 2 error, 3 base has no benchmarks to compare.

set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
base_ref="HEAD~1"
head_ref="HEAD"
launches=5
out=""
filter=""
frames=""
report=""
tools_ref=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --base) base_ref="$2"; shift 2 ;;
        --head) head_ref="$2"; shift 2 ;;
        --launches) launches="$2"; shift 2 ;;
        --out) out="$2"; shift 2 ;;
        --filter) filter="$2"; shift 2 ;;
        --frames) frames="$2"; shift 2 ;;
        --report) report="$2"; shift 2 ;;
        --repo) repo="$(cd "$2" && pwd)"; shift 2 ;;
        --tools) tools_ref="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
done

base="$(git -C "$repo" rev-parse --short "$base_ref")"
head="$(git -C "$repo" rev-parse --short "$head_ref")"
out="${out:-$repo/build/ab/$base-vs-$head}"
rm -rf "$out/base" "$out/head"
mkdir -p "$out/base" "$out/head" "$out/logs"
out="$(cd "$out" && pwd)"

# Checks out a commit into its own worktree, once.
worktree_for() {
    local commit="$1"
    local path="$repo/build/worktrees/$commit"
    if [[ ! -d "$path" ]]; then
        git -C "$repo" worktree add --detach --quiet "$path" "$commit"
    fi
    echo "$path"
}

# Builds a commit's benchmarks in Release, once per commit. Returns 1 if it has none.
build() {
    local commit="$1" tree="$2"
    local derived="$repo/build/derived/$commit"
    if [[ ! -d "$tree/Mir/Tests/MirBenchmarks" ]]; then
        return 1
    fi
    if [[ -f "$derived/.built" ]]; then
        echo "Using the cached build of $commit"
        return 0
    fi
    echo "Building $commit (Release)..."
    (cd "$tree/Mir" && xcodebuild build-for-testing \
        -scheme Mir \
        -configuration Release \
        -destination 'platform=macOS' \
        -derivedDataPath "$derived" \
        > "$out/logs/build-$commit.log" 2>&1) || { tail -30 "$out/logs/build-$commit.log"; exit 2; }
    touch "$derived/.built"
}

# Runs one benchmark launch of a commit and writes its JSON into a side's folder.
run_launch() {
    local side="$1" commit="$2" tree="$3" index="$4"
    echo "  $side ($commit), launch $index"
    (cd "$tree/Mir" && \
        TEST_RUNNER_MIR_BENCH=1 \
        TEST_RUNNER_MIR_BENCH_COMMIT="$commit" \
        TEST_RUNNER_MIR_BENCH_LAUNCH="$index" \
        TEST_RUNNER_MIR_BENCH_OUTPUT_DIR="$out/$side" \
        TEST_RUNNER_MIR_BENCH_FILTER="$filter" \
        TEST_RUNNER_MIR_BENCH_FRAMES="$frames" \
        xcodebuild test-without-building \
            -scheme Mir \
            -configuration Release \
            -destination 'platform=macOS' \
            -derivedDataPath "$repo/build/derived/$commit" \
            -only-testing:MirBenchmarks \
            > "$out/logs/$side-$index.log" 2>&1) || { tail -30 "$out/logs/$side-$index.log"; exit 2; }
}

base_tree="$(worktree_for "$base")"
head_tree="$(worktree_for "$head")"
tools_tree="$repo"
if [[ -n "$tools_ref" ]]; then
    tools_tree="$(worktree_for "$(git -C "$repo" rev-parse --short "$tools_ref")")"
fi
if ! build "$base" "$base_tree"; then
    echo "Base $base has no benchmarks, so there is nothing to compare against."
    exit 3
fi
build "$head" "$head_tree" || { echo "Head $head has no benchmarks." >&2; exit 2; }

echo "Running $launches launches per side, interleaved"
for index in $(seq 1 "$launches"); do
    if (( index % 2 == 1 )); then
        run_launch base "$base" "$base_tree" "$index"
        run_launch head "$head" "$head_tree" "$index"
    else
        run_launch head "$head" "$head_tree" "$index"
        run_launch base "$base" "$base_tree" "$index"
    fi
done

compare=(swift run --quiet --package-path "$tools_tree/Tools/MirBench" -c release mir-bench compare
    --base "$out/base" --head "$out/head" --thresholds "$tools_tree/benchmarks/thresholds.json")
if [[ -n "$report" ]]; then
    compare+=(--markdown "$report")
fi
status=0
"${compare[@]}" | tee "$out/report.md" || status=$?
echo "Report: $out/report.md"
exit "$status"
