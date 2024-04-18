using Revise
using Intsect
using BenchmarkTools

board = handle_newgame_command(Gametype.MLP)

moves = "wA1;bB1 wA1-;wQ \\wA1;bQ bB1/;wP \\bB1"
for move in split(moves, ";")
    show(board, true)
    action = action_from_move_string(board, move)
    do_action(board, action)
end

show(board)
show(validactions(board))
