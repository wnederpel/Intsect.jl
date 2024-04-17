using Revise
using Intsect
using BenchmarkTools

board = handle_newgame_command(Gametype.MLP)

action = action_from_move_string(board, "wG1")
do_action(board, action)

action = action_from_move_string(board, "bA1 -wG1")
do_action(board, action)

action = action_from_move_string(board, "wQ wG1\\")
do_action(board, action)

action = action_from_move_string(board, "bG1 -bA1")
do_action(board, action)

show(action)
show(board)

show(grasshoppermoves(board, 36))

# println("ant moves moves for white at 12")
# println(antmoves(board, 12))