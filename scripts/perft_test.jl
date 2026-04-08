using Intsect: perft
using PProf: PProf
using Profile: Profile

depth = 5

gamestring = raw"Base+MLP;InProgress;Black[3];wA1;bA1 wA1/;wB1 wA1\;bA2 bA1/;wG1 /wA1;bQ bA1-;wQ -wG1;bA2 bQ\\"
perft(depth; game_string=gamestring, output=true)

Profile.clear()
Profile.@profile perft(depth; game_string=gamestring, output=false)
PProf.pprof()

# Collect an allocation profile
Profile.Allocs.clear()
Profile.Allocs.@profile sample_rate = 1 perft(depth; game_string=gamestring, output=false)
PProf.Allocs.pprof()
