using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile
board = handle_newgame_command(MLPGame)
movestrings = raw"wL;bL wL\;wM \wL;bM bL\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-;wA2 wQ\;bA2 bA1\;wA2 /bA2;bA1 /wA1;wB1 wQ\;bP bA2-;wM wB1\;bB1 \bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1;bQ bP-;wQ -wB1;bQ bM-;wQ \wB1;bB1 bL;wM wL;bQ wA2-"
# movestrings = raw"wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 /wA1;bB1 bA1\;wB2 \wA1"

for movestring in split(movestrings, ";")
    do_action(board, movestring)
end
before_hash = get_hash_value(board)
show(board)
println("start check!")

movestrings = raw"wM wA1"

for movestring in split(movestrings, ";")
    println(movestring)
    do_action(board, movestring)
end

undo(board)

intermediate_hash = get_hash_value(board)

# movestrings = raw"bQ bP-;wQ -wB1;bQ bM-;wQ \wB1"
# for movestring in split(movestrings, ";")
#     do_action(board, movestring)
# end

# after_hash = get_hash_value(board)

println(before_hash)
println(intermediate_hash)