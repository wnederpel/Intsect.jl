using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

game = raw"wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 -wQ;bB1 bQ-;wB1 wB1-;bB1 -bB1"
game = raw"wA1;bA1 wA1-;wQ -wA1;bQ bA1-"
movestrings = split(game, ';')

board = handle_newgame_command(Gametype.MLP)

for movestring in movestrings
    action = action_from_move_string(board, movestring)
    do_action(board, action)
    if board.current_color == BLACK
        # show(board.white_pieces)
        # show(board.white_adjacent)
    end
end

println("done doing actions")
println(length(validactions(board) |> y -> filter(x -> x isa Placement, y)))

# Profile.clear()
# Profile.@profile g(board, pinned_tiles)

# PProf.pprof()