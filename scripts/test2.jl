using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(Gametype.MLP)

do_action(board, "wL")
do_action(board, "bL wL-")

do_action(board, "wP -wL")
do_action(board, "bP bL-")

do_action(board, "wA1 -wP")
do_action(board, "bA1 bP-")
show(board)
show(board.white_pieces)
show(board.black_pieces)
show(extract_valid_actions(board))
adj = get_adjacent_bb(board.white_pieces)
show(adj)
do_action(board, "wQ -wA1")
