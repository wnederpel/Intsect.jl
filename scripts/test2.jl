using DataStructures
using Intsect
using BenchmarkTools
using PProf
using Profile

game = raw"wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 -wQ;bB1 bQ-;wB1 wB1-;bB1 -bB1"
movestrings = split(game, ';')

board = handle_newgame_command(Gametype.MLP)

for movestring in movestrings
    action = action_from_move_string(board, movestring)
    do_action(board, action)
end

actions = validactions(board)

pinned_tiles = Vector{Int}(undef, GRID_SIZE)

@btime get_pinned_tiles!($board, $pinned_tiles)

function g(board, pinned_tiles)
    for _ in 1:10000000
        get_pinned_tiles!(board, pinned_tiles)
    end
end

Profile.clear()
Profile.@profile g(board, pinned_tiles)

PProf.pprof()