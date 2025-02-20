using Intsect

board = handle_newgame_command(MLPGame)

gamestring = raw"Base+MLP;InProgress;white[11];wB1;bS1 wB1-;wQ /wB1;bQ bS1/;wG1 -wB1;bG1 bS1-;wM -wQ;bM bQ-;wP /wQ;bP bQ/;wL -wG1;bL bG1-;wA1 wQ\;bB1 \bQ;wS1 wA1-;bA1 -bB1;wA2 -wP;bA2 bP-;wA2 wS1/;bA2 /bA1"

movestrings = split(gamestring, ";")[(begin + 3):end]
for movestring in movestrings
    do_action(board, movestring)
end

perft(4; start_board=board)
