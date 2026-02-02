using Intsect

gamestring = raw"Base+MLP;InProgress;White[54];wL;bP wL/;wQ wL\;bM bP/;wA1 -wL;bQ bM\;wA2 wQ\;bA1 bQ/;wA2 bA1-;bL \bA1;wA3 -wA1;bA2 bL/;wA3 bA2-;bA3 -bA2;wA2 bQ\;bG1 \bA2;wA1 -bA3;bG1 wA1\;wG1 -wL;bM -wA1;wA2 \bA3;bG2 bG1\;wA3 bQ\;bA2 \wA2;wQ wG1\;bA1 wA3\;wQ /wG1;bB1 bL\;wP wG1\;bG3 bB1/;wG1 bP\;bQ -bP;wG2 wP\;bQ /bG1;wG2 wL\;wL bG2\;wG3 wG2\;bP /bQ;wQ /bP;bQ -bP;wG3 bP\;bS1 -bQ;wQ bS1\;bB2 bG3/;wS1 wP\;bS2 bB2\;wS1 /bA1;bS1 wQ\;wG3 \bP;bA2 wA2/;wS2 wG2\;bA1 \bA2;wA3 -wG3;bA1 \wA3;wS1 wP\;bA3 -wQ;wG3 bP\;bM -wA2;bS1 /wP;bA2 wA2-;wS2 /bS1;bA2 wA2/;wS2 bA3\;bS1 /wS2;wB1 /wP;bA2 wA2-;wG2 \bP;bA2 wA2/;wG2 wG3\;bA2 wA2-;wG2 \bP;bB2 bS2/;wG2 wG3\;bA2 wA2/;wG2 \bP;bB2 bS2-;wS1 bQ\;bB2 bS2/;wM wP\;bM -bA2;wB2 wG3\;bA3 \bA2;wM wQ\;bA3 -bB2;wQ /wA3;bQ /bG1;wL bQ\;bG2 -bA3;wG3 bG1\;wL wA3\;wB1 bP\;bA2 -wQ;wL bQ\;bA3 wG1-;wB1 bP;bB1 wG3;wB2 wB1\;bA3 wG1\;wS1 wP\;bA2 /wS1;wL wB2\;bA3 bL\;wB1 bQ;bA2 -wQ;wS1 /bP;wB2 wA3\\"

board = from_game_string(gamestring)
show(board)
show_valid_actions(board)
do_action(board, action_from_move_string(board, "wB1 bQ\\"))