function handle_info_command()
    println("id Intsect v0.1")
    println("Mosquito;Ladybug;Pillbug")
    return nothing
end

function start()
    handle_info_command()

    board = nothing
    gamestring = nothing
    start(board, gamestring)
    return nothing
end

function start(board, gamestring)
    while true
        prev_board = board
        command = readline()
        try
            if command == "info"
                handle_info_command()
            elseif command == "state"
                if gamestring === nothing
                    println("No game is started yet")
                else
                    show(gamestring)
                end
            elseif command == "exit"
                println("ok")
                break
            elseif startswith(command, "newgame")
                if occursin(";", command)
                    gamestring = command[9:end]
                    gametype_string = split(gamestring, ";")[1]
                    gametype = gametype_from_string(gametype_string)
                    board = handle_newgame_command(gametype)
                    moves = split(gamestring, ";")[4:end]
                    for move_string in moves
                        action = action_from_move_string(board, move_string)
                        do_action(board, action)
                    end
                else
                    gametype_string = command[9:end]
                    gametype = gametype_from_string(gametype_string)
                    board = handle_newgame_command(gametype)
                end
                gamestring = GameString(board)
                show(gamestring)

            elseif command == "options"
            elseif startswith(command, "help")
                println("Commands:")
                println("info")
                println("state")
                println("undo <moves_to_undo; default = 1>")
                println("newgame <gametype>")
                println("play <action>")
                println("show")
                println("pass")
                println("validmoves")
                println("bestmove")
                println("exit")
            elseif board === nothing
                println("No board is setup, please start a new game first")
            else
                if startswith(command, "play")
                    move_string = command[6:end]
                    action = action_from_move_string(board, move_string)
                    do_action(board, action)
                    update_gamestring(gamestring, board)
                    show(gamestring)
                elseif startswith(command, "perft")
                    max_depth = tryparse(Int, split(command, " ")[2])
                    max_depth = max_depth === nothing ? 4 : max_depth
                    println("depth \t\t count \t time \t kn/s")
                    for depth in 0:max_depth
                        nodes, time_taken, _, _, _ = @timed perft(depth, board)
                        kilo_nodes = nodes / 1000
                        knps = round(kilo_nodes / time_taken)
                        @printf("%6d%14d%12s%12.1f\n", depth, nodes, format_time(time_taken), knps)
                    end
                elseif startswith(command, "bestmove")

                    type = split(command, " ")[2] == "time" ? :time : :depth
                    if type == :depth
                        depth = tryparse(Int, split(command, " ")[3])
                        if depth === nothing
                            error("please supply depth")
                        end

                        action = get_best_move(board, depth, 10)
                    else
                        time_str = split(command, " ")[3]
                        hours, minutes, seconds = tryparse.(Int, split(time_str, ":"))
                        if hours === nothing || minutes === nothing || seconds == nothing
                            error("time $time_str is not in valid format hh:mm:ss")
                        end
                        seconds_total = seconds + minutes * 60 + hours * 3600

                        action = get_best_move(board, 3, seconds_total)
                    end

                    show(action, board)

                elseif command == "show"
                    show(board; show_locs=false, simple=false)
                elseif command == "pass"
                    do_action(board, Pass())
                    update_gamestring(gamestring, board)
                    show(gamestring)
                elseif command == "validmoves"
                    actions = validactions(board)
                    print(move_string_from_action(board, actions[begin]))
                    for action in actions[(begin + 1):end]
                        print(";" * move_string_from_action(board, action))
                    end
                    println()
                elseif startswith(command, "undo")
                    moves_to_undo = tryparse(Int, command[6:end])
                    if isnothing(moves_to_undo)
                        moves_to_undo = 1
                    end

                    for _ in 1:moves_to_undo
                        undo(board)
                    end
                    update_gamestring(gamestring, board)
                    show(gamestring)
                else
                    println("Unknown command: '$command'")
                end
            end
            println("ok")
        catch e
            if isa(e, ErrorException)
                println("err " * e.msg)
            else
                io = IOBuffer()
                # Write the error message to the IOBuffer
                showerror(io, e)
                println("An error occurred: ", String(take!(io)))

                # Capture the full stack trace
                full_backtrace = catch_backtrace()
                # Select only the first 5 elements, if there are that many
                short_backtrace = full_backtrace[begin:(begin + 10)]

                # Reset the IOBuffer to reuse it for the backtrace
                seekstart(io)
                truncate(io, 0)

                # Write the shortened stack trace to the IOBuffer
                Base.show_backtrace(io, short_backtrace)
                # Print the formatted short stack trace
                println(String(take!(io)))
                println()
            end
            if board !== nothing
                board = prev_board
            end
            show(gamestring)
            println("ok")
        end
    end
    return nothing
end

function example()
    gametype = MLPGame
    board = handle_newgame_command(gametype)
    gamestring = GameString()
    show(gamestring)
    println("ok")

    action = action_from_move_string(board, "wL")
    do_action(board, action)
    update_gamestring(gamestring, board)
    show(gamestring)
    println("ok")

    start(board, gamestring)
    return nothing
end

# format seconds into ns / µs / ms / s with one decimal
function format_time(t::Float64)::String
    if t < 1e-6
        @sprintf("%.1fns", t * 1e9)
    elseif t < 1e-3
        @sprintf("%.1fµs", t * 1e6)
    elseif t < 1
        @sprintf("%.1fms", t * 1e3)
    else
        @sprintf("%.1fs", t)
    end
end
