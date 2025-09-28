using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(MLPGame)
actions = [
    Placement(136, 0x04),
    Placement(120, 0x38),
    Placement(135, 0x24),
    Placement(103, 0x20),
    Move(135, 119),
    Move(136, 104),
]

for action in actions
    do_action(board, action)
end

show(board)
show(board.white_pieces)
show(board.black_pieces)

undo(board)

show(board)
show(board.white_pieces)
show(board.black_pieces)