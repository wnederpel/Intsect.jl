using Intsect
using BenchmarkTools
using PProf
using Profile

perft()

# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 0.01 perft()

# PProf.Allocs.pprof()

Profile.clear()
Profile.@profile perft()

PProf.pprof()
