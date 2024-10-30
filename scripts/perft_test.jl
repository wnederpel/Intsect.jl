using Intsect
using BenchmarkTools
using PProf
using Profile

depth = 6
perft(depth; output=true)
# (@benchmark perft(5; output=false)) |> display

# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 0.01 perft(depth; output=false)

# PProf.Allocs.pprof()

Profile.clear()
Profile.@profile perft(depth; output=false)

PProf.pprof()
