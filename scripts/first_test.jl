using Revise
using Intsect
using BenchmarkTools
using Bumper
using PProf
using Profile

game1 = raw"wA1;bA1 \wA1;wQ wA1-;bQ bA1/;wP wQ/;bP bQ/"
game2 = raw"wA1;bA1 \wA1;wA2 wA1-;bA2 bA1/;wP wA2/"
movestrings1 = split(game1, ';')
movestrings2 = split(game2, ';')

board = handle_newgame_command(Gametype.MLP)

const actions1 = map(
    movestring -> begin
        action = action_from_move_string(board, movestring)
        do_action(board, action)
        return action
    end, movestrings1
)

for _ in actions1
    undo(board)
end

const actions2 = map(
    movestring -> begin
        action = action_from_move_string(board, movestring)
        do_action(board, action)
        return action
    end, movestrings2
)

for _ in actions2
    undo(board)
end

function f(board)
    for action in actions1
        do_action(board, action)
        undo(board)
        do_action(board, action)
    end

    for _ in actions1
        undo(board)
    end

    for action in actions2
        do_action(board, action)
        undo(board)
        do_action(board, action)
    end

    for _ in actions2
        undo(board)
    end
end

f(board)

@btime f($board)

# Profile.clear()
# Profile.@profile for _ in 1:100_000
#     f(board)
# end

# PProf.pprof()
