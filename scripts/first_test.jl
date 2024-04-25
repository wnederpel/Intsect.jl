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

w1 = "wM"
w2 = "wQ"
b1 = "bP"
b2 = "bQ"

board = handle_newgame_command(Gametype.MLP)

do_action(board, action_from_move_string(board, w1))
do_action(board, action_from_move_string(board, b1 * " " * w1 * "-"))

do_action(board, action_from_move_string(board, w2 * " /" * w1))
do_action(board, action_from_move_string(board, b2 * " " * b1 * "/"))

show(board)
actions = validactions(board)
show(actions, board)