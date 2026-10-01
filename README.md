# Mir

Mir is a Metal-powered framework for interactive maps and navigation experiences.

![The default Mir globe, rendered offscreen by the test suite](.github/assets/globe.png)

## Testing

Run the tests with `xcodebuild`, which compiles the Metal shaders (`swift test` doesn't):

```bash
cd Mir
xcodebuild test -scheme Mir -destination 'platform=macOS'
```

To save the frames the render tests draw as PNG files, pass a folder in `TEST_RUNNER_MIR_TEST_OUTPUT_DIR`.

## Benchmarks

See [BENCHMARKS.md](BENCHMARKS.md) for the design and results so far. The benchmark suite renders offscreen with fixed inputs and records exact work counters, CPU counters and timings. It runs in Release builds, one JSON file per launch.

```bash
scripts/bench.sh --launches 5
swift run --package-path Tools/MirBench mir-bench summary build/bench/<commit>
```

`scripts/perf-ab.sh` is the regression gate: it builds two commits, runs their launches interleaved (A, B, B, A, ...) and exits with 1 if `mir-bench compare` finds a regression under `benchmarks/thresholds.json`.

```bash
scripts/perf-ab.sh --base HEAD~1 --head HEAD
```

`scripts/bisect-perf.sh` finds the commit that introduced a regression, for `git bisect run`; its header explains how to run it. Builds are cached per commit in `build/`; remove `build/` and run `git worktree prune` to clear them.

## Performance CI

`.github/workflows/perf.yml` runs the A/B gate on a self-hosted Mac labelled `perf-m4pro`, only on pushes to this repository's branches and manual runs, never on pull requests. To set the runner up, add a macOS ARM64 runner in the repository's Settings → Actions → Runners with the extra label `perf-m4pro`, install it as a service with `./svc.sh install` so it runs in your logged-in session, require approval for workflows from outside contributors, then set the repository variable `PERF_RUNNER` to `enabled`. Until then the job is skipped.
