using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(Gametype.MLP)

actions = [
    Placement(136, 0x14),
    Placement(120, 0x10),
    Placement(135, 0x24),
    Placement(103, 0x20),
    Move(135, 119),
    Climb(120, 103),
    # Climb(136, 135),
    # Climb(103, 104),
]

for action in actions
    do_action(board, action)
end

perft(2, board)