using Intsect

board = from_game_string(
    raw"Base+MLP;InProgress;White[10];wL;bL wL\;wA1 \wL;bM bL\;wQ /wA1;bA1 /bL;wA1 bM-;bQ bA1\;wA2 \wL;bA1 \wA2;wQ /wL;bS1 /bQ;wM /wA2;bS1 /wQ;wP -wM;bA1 wA2/;wA1 bM\;bQ /wA1;wL \bA1;bP bQ\\",
)

evaluate_board(board; debug=true) |> println
show(board)

board = from_game_string(
    raw"Base+MLP;InProgress;White[10];wL;bL wL\;wA1 \wL;bM bL\;wQ /wA1;bA1 /bL;wA1 bM-;bQ bA1\;wA2 \wL;bA1 \wA2;wQ /wL;bS1 /bQ;wM /wA2;bS1 /wQ;wP -wM;bA1 wA2/;wA1 bM\;bQ /wA1;wL /bM;bP bQ\\",
)

evaluate_board(board; debug=true) |> println
show(board)