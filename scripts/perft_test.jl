using Intsect
using BenchmarkTools
using PProf
using Profile

get_pinned_tiles(board)

# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 1.0 get_pinned_tiles(board)

# PProf.Allocs.pprof()

Profile.clear()
Profile.@profile get_pinned_tiles(board)

PProf.pprof()
