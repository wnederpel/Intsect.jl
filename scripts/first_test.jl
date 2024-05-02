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

do_action(board, action_from_move_string(board, "wQ -wP"))
do_action(board, action_from_move_string(board, "bQ bP-"))

show(board, true)

is_pinned = get_pinned_tiles(board)
println(is_pinned)

actions = validactions(board)

show(actions, board)
