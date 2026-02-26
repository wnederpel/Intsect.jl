using Intsect

gamestring = raw"Base+MLP;InProgress;White[26];wL;bL wL\;wM \wL;bM bL\;wA1 wL/;bQ /bL;wQ /wM;bA1 bM/;wM bM\;bA2 /bQ;wA1 -bA2;bB1 bA1-;wP \wL;bA3 bB1\;wB1 wL/;bA3 -bQ;wA2 -wP;bB2 \bB1;wA2 bB1\;bA2 \wB1;wB1 bA2;bB2 \bA1;wA2 bB2/;bB1 bA1\;wB2 /wM;bA1 wB1/;wQ -wP;bA1 -wQ;wS1 /wA1;bA1 \wQ;wA3 wM\;bA1 wB1/;wA3 bA1/;bB1 wM;wA2 bB2-;bB1 bB1/;wG1 wM\;bB1 wM;wB2 bB1;bS1 \bA3;wS1 -bS1;pass;wS2 /wG1;pass;wS2 bA3\;pass;wA1 wB1\;pass;wL wB2/"

board = from_game_string(gamestring)
show(board)
show_valid_actions(board)

do_action(board, "pass")

show(board)
show_valid_actions(board)
