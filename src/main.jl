function handle_info_command()
    println("id HiveMind v0.1")
    println("Mosquito;Ladybug;Pillbug")
    return nothing
end

function main()
    println(handle_info_command())
    println("Enter a command:")
    board = nothing
    game_string = ""
    while true
        prev_board = board
        command = readline()
        try
            if command == "info"
                handle_info_command()
            elseif command == "exit"
                println("Exiting...")
                break
            elseif startswith(command, "newgame")
                if occursin(";", command)
                    println("newgame with game string not yet supported")
                end
                gametype_string = command[9:end]

                gametype = gametype_from_string(gametype_string)
                board = handle_newgame_command(gametype)
                game_string = "Base+MLP;NotStarted;White[1]"

                println(game_string)
            elseif startswith(command, "play")
                move_string = command[6:end]
                if board !== nothing
                    action = action_from_move_string(board, move_string)
                    do_action(board, action)
                    game_string *= ";" * move_string
                    println(game_string)
                else
                    println("unable to move, no board is setup")
                end
            elseif command == "show"
                if board !== nothing
                    show(board)
                else
                    println("nothing to show, no board is setup")
                end
            elseif command == "pass"
                game_string *= ";pass"
                println(game_string)
            elseif command == "validmoved"
                valid_moves = validmoves(board)
                println(valid_moves)
            else
                println("Unknown command: '$command'")
            end
            println("ok")
        catch e
            if isa(e, ErrorException)
                println("err" * e.msg)
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
            end
            if board !== nothing
                board = prev_board
            end
            println("ok")
        end
    end
end
