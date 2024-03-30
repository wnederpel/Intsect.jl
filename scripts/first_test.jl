using Revise
using Intsect
using BenchmarkTools

board = handle_newgame_command(Gametype.MLP)

action = action_from_move_string(board, "wA1")
do_action(board, action)
show(action)
show(board)

action = action_from_move_string(board, "bS2 wA1-")
do_action(board, action)
show(action)
show(board)

action = action_from_move_string(board, "wB1 /wA1")
do_action(board, action)
show(action)
show(board)

action = action_from_move_string(board, "bB1 bS2-")
do_action(board, action)
show(action)
show(board)

action = action_from_move_string(board, "wG1 wA1\\")
do_action(board, action)
show(action)
show(board)

action = action_from_move_string(board, "wL wA1/")
do_action(board, action)
show(action)
show(board)

println("spider moves moves for white")
println(spidermoves(board, 7))