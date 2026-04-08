---
description: "Use when profiling Julia code, optimizing performance, benchmarking, reducing allocations, or analyzing hot paths in Intsect"
applyTo: "src/**"
---
# Profiling Guidelines
when profiling, create as script that does the profiling for you and call it using the MCP tool with `using("scripts/your_script.jl")`
## Running profiling scripts

Run profiling scripts using the `mcp_julia-repl_exec_repl` MCP tool (never via `julia` in a terminal).
Profiling scripts live in `scripts/` (e.g. `scripts/perft_test.jl`, `scripts/perft_benchmark.jl`).

## Agent-readable output

Do NOT use `PProf.pprof()` — it starts a localhost web UI that agents cannot access.
Instead, use text-based output that prints to stdout:

**CPU profile (flat summary):**
```julia
using Profile
Profile.clear()
Profile.@profile my_function()
Profile.print(format=:flat, sortedby=:count)
```

**CPU profile (tree view):**
```julia
Profile.print(IOContext(stdout, :displaysize => (200, 500)))
```

**Write profile to a file for inspection:**
```julia
open("tmp/prof.txt", "w") do io
    Profile.print(IOContext(io, :displaysize => (200, 500)))
end
```

**Allocation profile (text-based):**
```julia
using Profile
Profile.Allocs.clear()
Profile.Allocs.@profile sample_rate = 1 my_function()
# Read the results programmatically:
results = Profile.Allocs.fetch()
```

## Benchmarking

Use `BenchmarkTools` for timing:
```julia
using BenchmarkTools
@btime my_function()
```

## Perft as a performance benchmark

The `perft` function is the primary benchmark for move generation. Run it with `output=true` to get KN/s and memory stats:
```julia
using Intsect: perft
perft(5; game_string=gamestring, output=true)
gamestring = raw"Base+MLP;InProgress;Black[3];wA1;bA1 wA1/;wB1 wA1\;bA2 bA1/;wG1 /wA1;bQ bA1-;wQ -wG1;bA2 bQ\\"
```

Compare KN/s and memory-per-node before and after changes. Record results in `data/PERFT_RESULTS.md`.