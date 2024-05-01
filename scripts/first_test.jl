using Revise
using Intsect
using BenchmarkTools

# ANT = 0         # 3
# GRASSHOPPER = 1 # 3
# BEETLE = 2      # 2
# SPIDER = 3      # 2
# QUEEN = 4       # 1
# LADYBUG = 5     # 1
# MOSQUITO = 6    # 1
# PILLBUG = 7     # 1

# w1 = "wP"
# w2 = "wL"
# w3 = "wM"

# b1 = "bA1"
# b2 = "bA2"
# b3 = "bA3"

board = handle_newgame_command(Gametype.MLP)

do_action(board, action_from_move_string(board, "wP"))
do_action(board, action_from_move_string(board, "bP wP-"))
undo(board)
do_action(board, action_from_move_string(board, "bP wP\\"))
undo(board)
do_action(board, action_from_move_string(board, "bP wP/"))

# do_action(board, action_from_move_string(board, w3 * " \\" * w2))
# do_action(board, action_from_move_string(board, b3 * " " * b2 * "/"))

show(board, true)
println(board.placeable_tiles[1])
println(board.placeable_tiles[2])

actions = validactions(board)

show(actions, board)
