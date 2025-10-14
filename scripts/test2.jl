using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(MLPGame)
movestrings = raw"wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 wQ\;bB1 bA1\;wB2 \wA1;bB2 \bQ;wB1 wA1;bB1 bA1;wB2 wB1;bG1 bB1\;wB2 bB1;bB2 wB2;wB1 bB2;bA2 bQ-;wL \wA1;bL /bG1;wA2 -wQ;bA3 \bA2;wB1 bQ;bB2 wA1/"
# movestrings = raw"wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 /wA1;bB1 bA1\;wB2 \wA1"

for movestring in split(movestrings, ";")
    do_action(board, movestring)
end
depth = 1
# do_action(board, )
# show(board)
# show(board.pieces[WHITE])
# show(board.pieces[BLACK])
println("start")
before_out = perft(depth, board)

extra_moves = [Move(134, 102), Move(170, 155), Move(135, 152)]
for move in extra_moves
    do_action(board, move)
end
for _ in extra_moves
    undo(board)
end

# show_pinned(board)
# show_valid_actions(board)

# println(board.underworld[137])
# println(board.underworld[138])

after_out = perft(depth, board)

println("$before_out !=? $after_out")