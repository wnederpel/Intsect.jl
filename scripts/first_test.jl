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

w1 = "wP"
w2 = "wQ"
w3 = "wM"

b1 = "bB1"
b2 = "bB2"
b3 = "bA1"

# Add a test case for this!
game = raw"wA1;bA1 \wA1;wQ wA1-;bQ bA1/;wP wQ/"
movestrings = split(game, ';')

board = handle_newgame_command(Gametype.MLP)

for movestring in movestrings
    action = action_from_move_string(board, movestring)
    do_action(board, action)
end
undo(board)
action = action_from_move_string(board, "wA2 wQ-")
do_action(board, action)
do_action(board, raw"bQ \bA1")

show(board)

actions = filter(action -> !(action isa Placement), validactions(board))

show(actions, board)
