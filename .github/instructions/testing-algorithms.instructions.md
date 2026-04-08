---
description: "Use when making algorithmic improvements to search, evaluation, or move generation. Covers how to validate correctness, measure performance, and test playing strength."
applyTo: "src/ai/**"
---
# Testing Algorithmic Improvements

## Running tests and scripts

- Run unit tests via `julia --project=. test/runtests.jl` in a terminal.
- Run scripts (profiling, benchmarks, arenant) via the `mcp_julia-repl_exec_repl` MCP tool, NOT via `julia` in a terminal.

## Available validation methods

Choose the appropriate level(s) based on context:

### 1. Unit tests (`test/`)
Run the test suite to verify correctness after any change:
```
julia --project=. test/runtests.jl
```
Tests cover move generation, placement, game state, and perft correctness.

### 2. Perft correctness (`scripts/perft_test.jl`)
Verifies move generation produces the correct number of nodes at each depth. Use after changes to move generation or game state logic. Run via MCP REPL.

### 3. Perft benchmarks (`scripts/perft_benchmark.jl`)
Measures KN/s and memory per node. Use to verify performance improvements or catch regressions. See `profiling.instructions.md` for details on agent-readable output. Run via MCP REPL.

### 4. Arenant matches (`scripts/arenant.jl`)
Runs matches against other engines to test playing strength. Use after changes to search or evaluation:
```julia

time_limit = 0.02
debug = true
full_debug = false

Arenant.run_arena(; debug=debug, time_limit_s=time_limit, full_debug=full_debug, results_path="./arenant_results.txt")

```
Run via MCP REPL. Engine binaries are in `engines/`.
You can edit what engines fight each other in the arenant in engines.yaml

The results will be stored in ./arenant_results.txt and you can read this file to see the score. the 'source' engine is the current state of the code. This command can take ~5 minutes. When calling the arenant, set a timer to expire at 8 minutes to avoid getting stuck! When it failed because of the time out, don't try again.

## What to validate when
this is vibes based, you decide!