using Revise
using Intsect
using BenchmarkTools
using Bumper
using PProf
using Profile

# ANT = 0         # 3
# GRASSHOPPER = 1 # 3
# BEETLE = 2      # 2
# SPIDER = 3      # 2
# QUEEN = 4       # 1
# LADYBUG = 5     # 1
# MOSQUITO = 6    # 1
# PILLBUG = 7     # 1

w1 = "wP"
w2 = "wQ"
w3 = "wM"

b1 = "bB1"
b2 = "bB2"
b3 = "bA1"

# Add a test case for this!
game = raw"wA1;bA1 \wA1;wQ wA1-;bQ bA1/;wP wQ/"
movestrings = split(game, ';')

board = handle_newgame_command(Gametype.MLP)

for movestring in movestrings
    action = action_from_move_string(board, movestring)
    do_action(board, action)
end

function f(board)
    @no_escape PERFT_BUFFER[1] begin
        move_buffer = @alloc(eltype(Int), 100)
        validactions!(board, move_buffer)
    end
    return board.action_index - 1
end

function g(board)
    for _ in 1:100000000
        f(board)
    end
end

@btime f($board)

Profile.clear()
Profile.@profile g(board)

PProf.pprof()