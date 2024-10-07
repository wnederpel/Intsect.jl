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

board = handle_newgame_command(Gametype.MLP)

show(board)

action_to_do = validactions(board)[1]
do_action(board, action_to_do)

show(board)
show_valid_actions(board)