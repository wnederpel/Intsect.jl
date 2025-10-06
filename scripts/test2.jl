using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(MLPGame)

movestrings = [
    raw"wG1",
    raw"bG1 wG1-",
    raw"wB1 /wG1",
    raw"bB1 bG1-",
    raw"wQ \wB1",
    raw"bQ \bB1",
    raw"wL \wG1",
    raw"bB1 bQ",
    raw"wB1 wG1",
    raw"bM bB1\\",
]

wl_move = raw"wL \bG1"

for movestring in movestrings
    do_action(board, movestring)
end

show(board)
show_valid_actions(board)