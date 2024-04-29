function perft()
    # https://github.com/jonthysell/Mzinga/wiki/Perft
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
    # TODO speed: 
    # Look into using the smart julia allocation package to get stack allocations. I forgot the name
    if depth == 1
        return length(validactions(board))
    end

    nodes = 0

    for action in validactions(board)
        do_action(board, action)
        nodes += perft(depth - 1, board)
        undo(board)
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
