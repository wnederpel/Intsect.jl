function perft(; output=true)
    perft(5; output=output)
    return nothing
end

function perft(n; output=true)
    # https://github.com/jonthysell/Mzinga/wiki/Perft
    # TODO speed: look into bump allocations for the whole board maybe? would be cool. 
    for depth in 1:n
        nodes, time_taken, memory_allocated, gc_time, _ = @timed perft(
            depth, handle_newgame_command(Gametype.MLP)
        )
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
            move_buffer = @alloc(Int, VALID_BUFFER_SIZE)
            buffer_index = @alloc(Int, 1)
            buffer_index[1] = 1
            validactions!(board, move_buffer, buffer_index)
        end
        return buffer_index[1] - 1
    end

    nodes = 0

    @no_escape PERFT_BUFFER[depth] begin
        # TODO eff: have a buffer for each movement type to have more concrete types in code

        move_buffer = @alloc(Int, VALID_BUFFER_SIZE)
        buffer_index = @alloc(Int, 1)
        buffer_index[1] = 1
        validactions!(board, move_buffer, buffer_index)

        for action_i in 1:(buffer_index[1] - 1)
            action_as_index = move_buffer[action_i]
            do_action(board, action_as_index)

            nodes += perft(depth - 1, board)
            undo(board)
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
