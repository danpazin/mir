# Benchmarks

Mir's harness catches performance regressions per commit. It renders the globe offscreen with fixed inputs, measures every frame in three tiers, and fails a change only when it is both bigger than a limit and unlikely to be noise.

## What runs where

| Where | What runs | Gates on |
| --- | --- | --- |
| Every push and pull request, GitHub-hosted macOS 26 VM (`ci.yml`) | Environment probe; unit, camera and render tests with Metal API validation; work budgets; iPhone 17 simulator tests; iOS device build | Exact work counters and correctness |
| Every push to this repository's branches, a dedicated M4 Pro (`perf.yml`) | `scripts/perf-ab.sh`: base and head interleaved, 5 launches each | All three tiers |
| By hand | `scripts/bench.sh`, `scripts/bisect-perf.sh`, `mir-bench summary` | — |

Virtual machines get a paravirtual GPU and no CPU counters, so their timings are never gated.

## Metrics

| Tier | Metrics | Limit | Why |
| --- | --- | --- | --- |
| 1. Work counters | Draw calls and bytes uploaded per frame, render-target GPU memory | Any increase fails | Exact on every machine |
| 2. CPU counters | Instructions per frame (`proc_pid_rusage`) | +2% and p < 0.01 | Varied 0.0–0.6% between launches in an A/A run |
| 3. Measured | CPU encode time, submit-to-complete time, pipelined frame time | +10% and p < 0.01 | Closest to what users feel, but noisy |

GPU time, cycles, energy and memory footprint are recorded but not gated yet; `benchmarks/thresholds.json` says why for each.

## How noise is controlled

- Offscreen rendering, so the display's frame pacing never enters the numbers.
- Release builds through `package` access; tests and benchmarks never need a testability build.
- 10 warm-up frames, then 60 measured frames per benchmark, in 5 separate process launches.
- Each launch records the machine and its conditions and refuses to count if anything distorts timings: a Debug build, Metal validation, a debugger, Low Power Mode, a hot start or low thread priority.
- The A/B gate interleaves base and head launches (A, B, B, A, ...), so drift hits both sides.
- One median per launch is one sample; an exact one-sided Mann–Whitney U test compares the sides. With 5 vs 5 launches the smallest p-value is 1/252 ≈ 0.004.

## Results so far (M4 Pro, macOS 26.7)

| Run | Result |
| --- | --- |
| A/A, same commit on both sides | 0 of 106 metrics flagged |
| Upload the globe once (Metal 4) | 18 improvements, 0 regressions; CPU encode at level 6: 0.887 → 0.005 ms |
| One draw call instead of 81,920 (classic Metal) | 28 improvements, 0 regressions; CPU encode at level 6: 4.681 → 0.006 ms |
| Frames in flight (Metal 4) | Instructions per frame +7–8% (p = 0.004); accepted as a trade-off, see below |
| Bisection of an injected cache bug among 5 commits | Culprit found in 3 steps, 5 min 19 s |

The same unchanged code measured 3.83 ms per frame in one session and 4.68 ms in another while its instruction count barely moved, which is why the gate compares interleaved launches instead of stored history.

## A trade-off the gate made visible

Keeping three Metal 4 frames in flight fixed a real hazard: the renderer had reset its command allocator while the GPU could still be using it, which Metal forbids. The gate flagged the fix: about 16,000 more instructions per frame (+7–8%, p = 0.004), past the 2% limit.

- **First hypothesis, wrong:** the per-frame event wait. Skipping it when the frame was already finished changed nothing measurable, so that change was reverted.
- **Second hypothesis, confirmed:** the per-frame event signal. An experiment without it (branch `experiment/no-event-signal`) brought instructions back to the old level.
- **But** the same experiment made submit-to-complete time 36–116% slower (0.222 → 0.480 ms at 1080p, level 6). The signal appears to get the GPU's work finished sooner; the mechanism isn't verified.

So the signal stays. About 4 µs of CPU per frame buys correctness and lower latency. Instructions are a proxy for cost; when they disagree with what users feel, latency wins.

Frames in flight also enabled the throughput benchmarks: at 4K, level 6, Metal 4 draws a frame every 0.097 ms when pipelined, against 0.28 ms when each frame waits for the last, about 2.9× the frames per second.

## Running it

```bash
scripts/bench.sh --launches 5                        # benchmark this commit
swift run --package-path Tools/MirBench mir-bench summary build/bench/<commit>
scripts/perf-ab.sh --base HEAD~1 --head HEAD         # the gate: exit 1 on regression
```

`scripts/bisect-perf.sh` drives `git bisect run`; its header shows how.

## Next

- A scripted camera path, to measure frame pacing and hitches the way pan and zoom latency would be.
- The paired iPhone as a second device in the perf job.
- Traces attached to regressions: an Instruments trace of base and head for the benchmark that failed.
- Change point detection over the history, to catch slow creep that no single A/B sees.
