using Revise
using Intsect
using BenchmarkTools

board = handle_newgame_command(Gametype.MLP)

action = action_from_move_string(board, "wA1")
do_action(board, action)

action = action_from_move_string(board, "bS2 wA1-")
do_action(board, action)

action = action_from_move_string(board, "bS1 wA1/")
do_action(board, action)

show(action)
show(board)

println("ant moves moves for white at 12")
println(antmoves(board, 12))