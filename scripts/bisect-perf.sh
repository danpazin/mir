#!/bin/bash
# bisect-perf.sh
# Mir
#
# SPDX-License-Identifier: Apache-2.0
# Copyright © 2026 Daniil Pazin. All rights reserved.
#
# Answers `git bisect run`'s question for one commit: is it slower than a known-good commit?
# Each step is a small interleaved A/B (perf-ab.sh) of the commit under test against the good
# commit, limited to one benchmark so a step takes about a minute. The good commit's build is
# cached, so it is built only once for the whole bisection.
#
# git bisect checks out older commits, which may not have these scripts, so run a copy from
# outside the repository. The analysis tool and thresholds come from a fixed tools commit.
#
# Usage:
#   cp scripts/bisect-perf.sh scripts/perf-ab.sh /tmp/
#   git bisect start <bad> <good>
#   git bisect run /tmp/bisect-perf.sh --good <good> --filter frame/metal4/1080p/level6 \
#       --repo "$PWD" --tools <commit with Tools/MirBench>
#
# Exit codes, as git bisect expects: 0 good, 1 bad, 125 skip (no benchmarks or build failure).

set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
good=""
filter=""
repo=""
tools=""
launches=5

while [[ $# -gt 0 ]]; do
    case "$1" in
        --good) good="$2"; shift 2 ;;
        --filter) filter="$2"; shift 2 ;;
        --repo) repo="$2"; shift 2 ;;
        --tools) tools="$2"; shift 2 ;;
        --launches) launches="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 125 ;;
    esac
done

if [[ -z "$good" || -z "$repo" || -z "$tools" ]]; then
    echo "bisect-perf.sh needs --good, --repo and --tools" >&2
    exit 125
fi

commit="$(git -C "$repo" rev-parse --short HEAD)"
echo "Testing $commit against good $good"
"$here/perf-ab.sh" --repo "$repo" --tools "$tools" --base "$good" --head "$commit" \
    --launches "$launches" --filter "$filter" --out "$repo/build/bisect/$commit"
case $? in
    0) echo "$commit: good"; exit 0 ;;
    1) echo "$commit: bad"; exit 1 ;;
    *) echo "$commit: skipped"; exit 125 ;;
esac
