function handle_info_command()
    println("id Intsect v0.1")
    println("Mosquito;Ladybug;Pillbug")
    return nothing
end

function main()
    println(handle_info_command())
    println("Enter a command:")
    board = nothing
    gamestring = nothing
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
                gamestring = GameString()

                show(gamestring)
            elseif startswith(command, "help")
                println("Commands:")
                println("info")
                println("newgame <gametype>")
                println("play <move>")
                println("show")
                println("pass")
                println("validmoves")
                println("exit")
            elseif board === nothing
                println("No board is setup, please start a new game first")
            else
                if startswith(command, "play")
                    move_string = command[6:end]
                    action = action_from_move_string(board, move_string)
                    do_action(board, action)
                    update_gamestring(gamestring, board, action)
                    show(gamestring)
                elseif command == "show"
                    show(board)
                elseif command == "pass"
                    gamestring *= ";pass"
                    println(gamestring)
                elseif command == "validmoves"
                    actions = validactions(board)
                    print(move_string_from_action(board, actions[begin]))
                    for action in actions[(begin + 1):end]
                        print(";" * move_string_from_action(board, action))
                    end
                    println()
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
end
