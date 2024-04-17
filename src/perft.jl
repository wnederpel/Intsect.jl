function perft()
    # https://github.com/jonthysell/Mzinga/wiki/Perft
    empty!(memoize_cache(positions))
    for n in 0:4
        time = @elapsed perftn = length(positions(n))
        println("Perft($n) = $perftn")
        println("time per node = $(time / perftn)")
    end
end

@memoize function positions(n::Int)::Vector{Board}
    if n == 0
        return [handle_newgame_command(Gametype.MLP)]
    else
        boards = Vector{Board}()
        for board in positions(n - 1)
            for action in validactions(board)
                newboard = deepcopy(board)
                do_action(newboard, action)
                push!(boards, newboard)
            end
        end
        return boards
    end
end
