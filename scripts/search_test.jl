using Intsect

board = handle_newgame_command(MLPGame)

board = from_game_string(
    raw"Base+MLP;InProgress;white[1];wL;bL wL-;wM -wL;bQ bL\;wQ \wL;bA1 bQ/;wA1 wM\;bA1 -wM;wA2 wQ/;bA2 bL/;wA3 -wA2;bA2 wA1\;wA2 /bQ;bL wQ/;wG1 wA2\;bA1 bL\;wG2 \wA3;bA3 bL/;wM bA3-;bA1 /wA3;wG2 wL\;bA2 \wA3;wA1 -bA1;bQ wG1/;wG3 /wA2;bQ wG1-;wB1 /wG2;bQ wG1\;wA2 \wM;bQ wG1-;wP wG2\;bQ wG1\;wB2 /wL;bM bA2/;wS1 wM/;bM bL\;wG2 \bA2;bG1 bM-;wS1 bG1-;bQ wG1-;wS2 wS1/;bS1 bQ-;wA1 /bA1;bS1 wP/;wG3 bS1\;bQ wG1\;wA1 bA2/;bS1 bG1\;wA1 -bA1;bS2 bQ\;wA2 /bS2;bG2 bS2/",
)

time_limit_s = 0.1
best_action = get_best_move(
    board; time_limit_s=time_limit_s, debug=false, method=:iterative_deepening
)
show(best_action, board)

show(board)