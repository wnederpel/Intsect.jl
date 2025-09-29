using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(MLPGame)
actions = [
    Placement(136, 0x14),
    Placement(137, 0x18),
    Placement(152, 0x24),
    Placement(121, 0x20),
    Placement(135, 0x0c),
    Placement(138, 0x08),
    Placement(151, 0x3c),
    Placement(122, 0x38),
    Placement(168, 0x34),
    Placement(105, 0x30),
    Placement(134, 0x2c),
    Placement(139, 0x28),
    Placement(169, 0x04),
    Placement(104, 0x10),
    Placement(170, 0x1c),
    Placement(103, 0x00),
    Placement(167, 0x44),
    Placement(106, 0x40),
    Move(167, 154),
    Move(106, 119),
    Move(169, 106),
    Move(119, 86),
]

for action in actions
    do_action(board, action)
    # show(board)
    # show_valid_actions(board)
end
