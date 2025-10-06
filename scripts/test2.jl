using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(MLPGame)

movestrings = raw"wB1;bS1 wB1-;wQ /wB1;bQ bS1/;wG1 -wB1;bG1 bS1-;wM -wQ;bM bQ-;wP /wQ;bP bQ/;wL -wG1;bL bG1-;wA1 wQ\;bB1 \bQ;wS1 wA1-;bA1 -bB1;wA2 -wP;bA2 bP-;wA2 wS1/;bA2 /bA1;wB1 wG1\;"[begin:(end - 1)]

for movestring in split(movestrings, ";")
    do_action(board, movestring)
end

show(board)
undo(board)
show(board)
# do_action(board, movestring)