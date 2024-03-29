using Revise
using HiveMind
using BenchmarkTools

board = handle_newgame_command(Gametype.MLP)

action = action_from_move_string(board, "wA1")
do_action(board, action)
show(action)
show(board)

action = action_from_move_string(board, "bA2 wA1-")
do_action(board, action)
show(action)
show(board)

println("ant moves for white")
@btime antmoves(board, 12)
println("spider moves for white")
@btime spidermoves(board, 12)
# println("locs for black")
# display(generate_placement_locs(board, 0))