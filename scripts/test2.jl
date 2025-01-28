using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(Gametype.MLP)

movestrings = [
    raw"wP",
    raw"bP wP-",
    raw"wQ \wP",
    raw"bQ bP\\",
    raw"wB1 /wP",
    raw"bB1 bQ-",
    raw"wB1 wP",
    raw"bM bB1-",
    raw"wQ \bP",
]

for movestring in movestrings
    do_action(board, movestring)
end

show(board)

show_valid_actions(board)

action_from_move_string(board, raw"wP bP/") |> println
