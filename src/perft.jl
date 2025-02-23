function perft(; output=true)
    perft(5; output=output)
    return nothing
end

function perft(n; output=true, type=MLPGame, game_string="Base+MLP;InProgress;white[11]")
    # https://github.com/jonthysell/Mzinga/wiki/Perft
    board = handle_newgame_command(type)
    movestrings = split(game_string, ";")
    if length(movestrings) > 3
        movestrings = movestrings[(begin + 3):end]
        for movestring in movestrings
            do_action(board, movestring)
        end
    end

    for depth in 1:n
        nodes, time_taken, memory_allocated, gc_time, _ = @timed perft(depth, board)
        if output
            println("Perft($depth) \t = $(format_with_dots(nodes))")
            kilo_nodes = nodes / 1000
            println("KN/S \t\t = $(format_with_dots(Int.(round(kilo_nodes / time_taken))))")
            println("memory per node  = $(round(memory_allocated / nodes, digits=2)) bytes")
            println("gc time \t = $(round(gc_time*100))%")
            println("total time \t = $(round(time_taken, digits=2)) seconds")
            println()
        end
    end
end

function perft(depth::Int, board)::Int
    if depth == 1
        # Not needed to allocate here, use a global valid move buffer,
        # Here you can just read the action_index.
        @no_escape PERFT_BUFFER[depth] begin
            move_buffer = @alloc(eltype(Int), VALID_BUFFER_SIZE)
            validactions!(board, move_buffer)
        end
        return board.action_index - 1
    end

    nodes = 0

    @no_escape PERFT_BUFFER[depth] begin
        # TODO eff: have a buffer for each movement type to have more concrete types in code

        move_buffer = @alloc(eltype(Int), VALID_BUFFER_SIZE)
        validactions!(board, move_buffer)
        for action_i in 1:(board.action_index - 1)
            action_as_index = move_buffer[action_i]

            do_action(board, action_as_index)

            # action = ALL_ACTIONS[action_as_index]
            # check_board(board, "after do $(typeof(action))", action, depth)

            nodes += perft(depth - 1, board)
            undo(board)

            # check_board(board, "after undo $(typeof(action))", action, depth)
        end
    end

    return nodes
end

function check_board(board, name, action, depth)
    if count_color_on_board(board; color=BLACK) != count_ones(board.black_pieces) ||
        count_color_on_board(board; color=WHITE) != count_ones(board.white_pieces)
        println("---------------------------------------")
        println(name)
        show(board; simple=true)
        # println(
        #     ALL_ACTIONS[getindex.(board.last_moves, 1)][(board.last_moves_index - 10):(board.last_moves_index)],
        # )
        # println(
        #     getindex.(board.last_moves, 2)[(board.last_moves_index - 10):(board.last_moves_index)],
        # )

        show(board.white_pieces)
        println(count_color_on_board(board; color=WHITE, show=true))
        show(board.black_pieces)
        println(count_color_on_board(board; color=BLACK, show=true))

        # println("looking back some moves")
        # for i in 0:0
        #     action_as_index, do_or_undo = board.last_moves[board.last_moves_index - (i * 2) - 1]
        #     if do_or_undo == :done
        #         println("undoing done move")
        #         println(ALL_ACTIONS[action_as_index])
        #         undo_action(board, action_as_index)
        #     else
        #         println("redoing undone move")
        #         do_action(board, action_as_index)
        #     end
        # end
        # show(board)
        println("last done / undone action:")
        show(action, board)
        println("perft depth $depth")
        error("This is wrong: $name")
    end
end

function format_with_dots(n)
    s = string(n)
    len = length(s)
    parts = []

    for i in len:-3:1
        start_index = max(i - 2, 1)
        push!(parts, s[start_index:i])
    end

    return join(reverse(parts), '.')
end

# begin
#     if action.goal_loc <= 84 || (board.ply == 3 && count_ones(board.black_pieces) == 2)
#         println("---------------------------------------")
#         println("bad in do!")
#         show(board; simple=true)
#         show(action)
#         println(
#             ALL_ACTIONS[getindex.(board.last_moves, 1)][(board.last_moves_index - 10):(board.last_moves_index)],
#         )
#         println(
#             getindex.(board.last_moves, 2)[(board.last_moves_index - 10):(board.last_moves_index)],
#         )

#         show(board.white_pieces)
#         show(board.black_pieces)

#         # println("looking back some moves")
#         # for i in 0:0
#         #     action_as_index, do_or_undo = board.last_moves[board.last_moves_index - (i * 2) - 1]
#         #     if do_or_undo == :done
#         #         println("undoing done move")
#         #         println(ALL_ACTIONS[action_as_index])
#         #         error("This is wrong")
#         #         undo_action(board, action_as_index)
#         #     else
#         #         println("redoing undone move")
#         #         error("This is wrong")
#         #         do_action(board, action_as_index)
#         #     end
#         # end
#         # show(board)

#         error("This is wrong in do")
#     end