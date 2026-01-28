using Intsect

game_string = raw"Base+MLP;InProgress;white[5];wL;bL wL\;wM \wL;bM bL\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-;wA2 wQ\;bA2 bA1\;wA2 /bA2;bA1 /wA1;wB1 wQ\;bP bA2-;wM wB1\;bB1 \bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1"

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