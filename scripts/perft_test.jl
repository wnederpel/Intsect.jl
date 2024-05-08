using Intsect
using BenchmarkTools
using PProf
using Profile

perft()

Profile.Allocs.clear()
Profile.Allocs.@profile sample_rate = 1.0 perft()

PProf.Allocs.pprof()

# Profile.clear()
# Profile.@profile perft()

# PProf.pprof()
