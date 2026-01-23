using Intsect

game_string_1 = "Base+MLP;InProgress;Black[5];wA1;bA1 wA1/;wA2 wA1\\;bA2 bA1/;wQ /wA1;bA3 bA2/;wA3 -wA1;bQ bA3\\;wB1 -wQ;bB1 bQ-;wB1 wA3"
# game_string_2 = "Base+MLP;InProgress;Black[5];wA1;bA1 wA1/;wA2 wA1\\;bA2 bA1/;wQ /wA1;bA3 bA2/;wA3 -wA1;bQ bA3\\;wA2 bQ-"

board_1 = from_game_string(game_string_1)
# board_2 = from_game_string(game_string_2)

show(board_1)

eval_1 = evaluate_board(board_1, WHITE)
# eval_2 = evaluate_board(board_2, WHITE)

println(eval_1)
# println(eval_2)ns
println()