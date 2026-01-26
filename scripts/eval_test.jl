using Intsect

game_string = "Base+MLP;InProgress;Black[5];wA1;bA1 wA1/;wA2 wA1\\;bA2 bA1/;wQ /wA1;bA3 bA2/;wA3 -wA1;bQ bA3\\"

board = from_game_string(game_string)

show(board)

@time get_best_move(board, 4, -1)

# Move: wA2 \bA3
# Best path (score: 25.0):
#   Move 1: Move: wA2 \bA3
#   Move 2: Placement: bL bQ/
#   Move 3: Move: wA3 bQ\
#   Move 4: Move: bL bA2\

# done
# Nodes processed: 24009124
# 16.0

# println(score)
println()