function perft()
    # https://github.com/jonthysell/Mzinga/wiki/Perft

    # TODO speed: look into bump allocations for the whole board maybe? would be cool. 
    # we cannot make an allocator for the actions, as action is an abstract type.
    # Maybe try to have separate buffers for each action type?

    for depth in 1:5
        nodes, time_taken, memory_allocated, gc_time, _ = @timed perft(
            depth, handle_newgame_command(Gametype.MLP)
        )
        println("Perft($depth) \t = $(format_with_dots(nodes))")
        kilo_nodes = nodes / 1000
        println("KN/S \t\t = $(format_with_dots(Int.(round(kilo_nodes / time_taken))))")
        println(
            "memory per node  = $(format_with_dots(Int(round(memory_allocated / nodes)))) bytes"
        )
        println("gc time \t = $(round(gc_time*100))%")
        println("total time \t = $(round(time_taken, digits=1)) seconds")
        println()
    end
end

function perft(depth::Int, board)::Int
    placement_index, move_index, climb_index = 1, 1, 1

    @no_escape begin
        placement_buffer = @alloc(Placement, 100)
        move_buffer = @alloc(Move, 100)
        climb_buffer = @alloc(Climb, 100)

        if depth == 1
            # Not needed to allocate here, use a global valid move buffer,
            # Here you can just read the action_index.
            nodes = length(
                validactions(
                    board,
                    placement_buffer,
                    placement_index,
                    move_buffer,
                    move_index,
                    climb_buffer,
                    climb_index,
                ),
            )
        else
            nodes = 0

            for action in validactions(
                board,
                placement_buffer,
                placement_index,
                move_buffer,
                move_index,
                climb_buffer,
                climb_index,
            )
                do_action(board, action)
                nodes += perft(depth - 1, board)
                undo(board)
            end
        end
    end

    return nodes
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
