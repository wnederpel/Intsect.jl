using Intsect
using BenchmarkTools
using PProf
using Profile

perft(5; output=false)
(@benchmark perft(5; output=false)) |> display

Profile.Allocs.clear()
Profile.Allocs.@profile sample_rate = 0.01 perft(output=false)

PProf.Allocs.pprof()

# Profile.clear()
# Profile.@profile perft()

# PProf.pprof()
