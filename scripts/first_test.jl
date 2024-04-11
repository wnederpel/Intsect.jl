using Revise
using Intsect
using BenchmarkTools

board = handle_newgame_command(Gametype.MLP)

action = action_from_move_string(board, "wL")
do_action(board, action)

action = action_from_move_string(board, "bS2 wL-")
do_action(board, action)

action = action_from_move_string(board, "bS1 wL-")
do_action(board, action)

show(action)
show(board)

println("ant moves moves for white at 12")
println(antmoves(board, 12))