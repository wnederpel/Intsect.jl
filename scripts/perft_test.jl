using Intsect
using BenchmarkTools
using PProf
using Profile

depth = 5

gamestring = raw"Base+MLP;InProgress;White[10];wS1;bS1 wS1-;wQ -wS1;bQ bS1\;wB1 -wQ;bB1 bQ-;wB1 wQ;bA1 bS1-;wM -wB1;bP bA1-;wL \wB1;bL bP-;wP \wL;bM bL-;wA1 -wP;bG1 bP\;wA1 wP-;bB1 bA1;wA2 wB1\;bB1 bS1;wA3 wB1/;bG2 bB1/;wB1 wA3;bM bQ-;wL -wA2"

perft(depth; game_string=gamestring, output=true)

# Profile.clear()
# Profile.@profile perft(depth; game_string=gamestring, output=false)
# PProf.pprof()

# Collect an allocation profile
# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 1 perft(depth; game_string=gamestring, output=false)

# PProf.Allocs.pprof()