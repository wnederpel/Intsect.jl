using Intsect
using BenchmarkTools
using PProf
using Profile

depth = 4
# gamestring = raw"Base+MLP;InProgress;white[5]"
gamestring = raw"Base+MLP;InProgress;white[5];wL;bL wL\;wM \wL;bM bL\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-;wA2 wQ\;bA2 bA1\;wA2 /bA2;bA1 /wA1;wB1 wQ\;bP bA2-;wM wB1\;bB1 \bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1
"
perft(depth; game_string=gamestring, output=true)

Profile.clear()
Profile.@profile perft(depth; game_string=gamestring, output=false)
PProf.pprof()

# Collect an allocation profile
# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 1 perft(depth; game_string=gamestring, output=false)
# PProf.Allocs.pprof()
