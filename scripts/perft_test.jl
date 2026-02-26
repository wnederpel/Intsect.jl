using Intsect: perft
using PProf: PProf
using Profile: Profile

depth = 5
# gamestring = raw"Base+MLP;InProgress;white[5]"
# gamestring = raw"Base+MLP;InProgress;white[11];wB1;bS1 wB1-;wQ /wB1;bQ bS1/;wG1 -wB1;bG1 bS1-;wM -wQ;bM bQ-;wP /wQ;bP bQ/;wL -wG1;bL bG1-;wA1 wQ\;bB1 \bQ;wS1 wA1-;bA1 -bB1;wA2 -wP;bA2 bP-;wA2 wS1/;bA2 /bA1"
gamestring = raw"Base+MLP;InProgress;Black[3];wA1;bA1 wA1/;wB1 wA1\;bA2 bA1/;wG1 /wA1;bQ bA1-;wQ -wG1;bA2 bQ\\"
for i in 1:depth
    perft(i; game_string=gamestring, output=true)
end
# Profile.clear()
# Profile.@profile perft(depth; game_string=gamestring, output=false)
# PProf.pprof()

# Collect an allocation profile
# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 1 perft(depth; game_string=gamestring, output=false)
# PProf.Allocs.pprof()
