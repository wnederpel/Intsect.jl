using Intsect

actions = [
    Placement(136, 0x04),
    Placement(120, 0x00),
    Placement(135, 0x44),
    Placement(103, 0x20),
    Placement(118, 0x84),
    Move(103, 104),
]

board = handle_newgame_command(MLPGame)

for action in actions
    do_action(board, action)
    show(board)
    show(board.white_pieces)
    show(board.black_pieces)
end
