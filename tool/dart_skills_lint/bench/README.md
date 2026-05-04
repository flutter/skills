# Performance benchmarks

When changing the validation loop, baseline I/O, or path-normalization code,
run the throughput benchmark to make sure you haven't regressed:

```bash
dart run bench/baseline_throughput.dart
```

This generates synthetic skills at multiple sizes, runs them through
`validateSkills` with `--generate-baseline`, and prints a wall-clock table.
The benchmark is intentionally not run in CI — wall-clock on hosted runners
is too noisy to enforce. Use it locally and compare your branch's table
against `main` before submitting changes.

## Options

```
--sizes              Comma-separated list of N values (default: 10,100,1000)
--errors-per-skill   Baseline-recordable errors per synthetic skill, 1-3 (default: 1)
--runs               Timed runs per cell (default: 3)
--warmup             Untimed warmup runs (default: 1)
```
