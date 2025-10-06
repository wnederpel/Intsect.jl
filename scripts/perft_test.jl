using Intsect
using BenchmarkTools
using PProf
using Profile

depth = 6

# gamestring = raw"Base+MLP;InProgress;white[11];wB1;bS1 wB1-;wQ /wB1;bQ bS1/;wG1 -wB1;bG1 bS1-;wM -wQ;bM bQ-;wP /wQ;bP bQ/;wL -wG1;bL bG1-;wA1 wQ\;bB1 \bQ;wS1 wA1-;bA1 -bB1;wA2 -wP;bA2 bP-;wA2 wS1/;bA2 /bA1"
gamestring = raw"Base+MLP;InProgress;white[1]"

# TODO: this is wrong at perft 3 ?!
# gamestring = raw"Base+MLP;InProgress;white[5];wL;bL wL\;wM \wL;bM bL\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-"

# gamestring = raw"Base+MLP;InProgress;white[5];wL;bL wL\;wM \wL;bM bL\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-;wA2 wQ\;bA2 bA1\;wA2 /bA2;bA1 /wA1;wB1 wQ\;bP bA2-"

perft(depth; game_string=gamestring, output=true)

Profile.clear()
Profile.@profile perft(depth; game_string=gamestring, output=false)
PProf.pprof()

# Collect an allocation profile
# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 0.01 perft(depth; game_string=gamestring, output=false)

# PProf.Allocs.pprof()