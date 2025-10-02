using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(MLPGame)
actions = [Placement(136, 0x14), Placement(137, 0x18)]

for action in actions
    do_action(board, action)
    show(board)
    show_valid_actions(board)
    # show(board.pieces[WHITE])
    # show(board.pieces[BLACK])
    # show(board.area[WHITE])
    # show(board.area[BLACK])
end
