using Intsect
using BenchmarkTools
using PProf
using Profile

@benchmark perft(5; output=false)

# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 0.001 perft()

# PProf.Allocs.pprof()

# Profile.clear()
# Profile.@profile perft()

# PProf.pprof()
