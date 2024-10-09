using Intsect
using BenchmarkTools
using PProf
using Profile

perft(6; output=true)
# (@benchmark perft(5; output=false)) |> display

Profile.Allocs.clear()
Profile.Allocs.@profile sample_rate = 0.01 perft(6; output=false)

PProf.Allocs.pprof()

# Profile.clear()
# Profile.@profile perft()

# PProf.pprof()
