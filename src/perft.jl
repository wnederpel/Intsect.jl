function perft()
    # https://github.com/jonthysell/Mzinga/wiki/Perft
    empty!(memoize_cache(positions))
    for n in 0:5
        nodes, time_taken, memory_allocated, gc_time, _ = @timed length(positions(n))
        println("Perft($n) = $nodes")
        kilo_nodes = nodes / 1000
        println("KN/S = $(round(kilo_nodes / time_taken, digits=2))")
        println("memory per node = $(Int(round(memory_allocated / nodes))) bytes")
        println("gc time  = $(round(gc_time*100, digits=2))%")
        println("total time = $time_taken seconds")
        println()
    end
end

# TODO perft: fix the tuple bug at n = 5
@memoize function positions(n::Int)::Vector{Board}
    if n == 0
        return [handle_newgame_command(Gametype.MLP)]
    else
        boards = MVector{Threads.nthreads(),Vector{Board}}(repeat([[]], Threads.nthreads()))
        positions_n_1 = positions(n - 1)
        # TODO speed: Move the parallelism to generating valid actions? That should be the more general solution
        # But the risk is that there are not enough valid moves per position to make the overhead worth it.
        @threads for board in positions_n_1
            for action in validactions(board)
                if !(action isa Union{Move,Placement,Climb,Pass})
                    println(action)
                    show(board)
                end
                newboard = deepcopy(board)
                do_action(newboard, action)
                push!(boards[threadid()], newboard)
            end
        end
        return vcat(boards...)
    end
end
