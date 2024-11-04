using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(Gametype.MLP)

game = raw"wS1;bS1 wS1-"
movestrings = strip.(split(game, ';'))

for movestring in movestrings
    action = action_from_move_string(board, movestring)
    do_action(board, action)
    show(board)
    show_pinned(board)
end
undo(board)

wS1 = get_tile_from_string("wS1")
bS1 = get_tile_from_string("bS1")

board = handle_newgame_command(Gametype.MLP)
wS1_loc = MID
bS1_loc = apply_direction(wS1_loc, Direction.E)

# Do the actions and check the board state 
action1 = Placement(wS1_loc, wS1)
do_action(board, action1)

action2 = Placement(bS1_loc, bS1)
do_action(board, action2)
show(board)
undo(board)
show(board)
