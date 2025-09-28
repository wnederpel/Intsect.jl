using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

board = handle_newgame_command(MLPGame)

movestrings = [raw"wP", raw"bP wP-", raw"wQ \wP", raw"bQ bP\\", raw"wB1 /wP"]

for movestring in movestrings
    do_action(board, movestring)
    println(board.hash)
end
