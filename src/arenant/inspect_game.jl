
"""
    inspect_game(game_string::String)

Inspect a game by stepping through moves forward and backward.

Commands:
- f/forward/Enter: Move forward one move
- b/back: Move back one move
- ff: Move forward 5 moves
- bb: Move back 5 moves
- s/show: Show current board state
- 0: Jump to start of game
- end: Jump to end of game
- h/help: Show help
- q/quit/exit: Exit inspector

Example:
```julia
inspect_game("Base+MLP;InProgress;white[1];wL;bP wL/;wA1 wL\\;bQ bP/")
```
"""
function inspect_game(game_string::String)
    println("=== Game Inspector ===")
    println("Type 'help' for commands")
    println()

    # Parse the game string to extract moves
    parts = split(game_string, ";")

    # The format is: GameType;Status;TurnInfo;move1;move2;...
    # We need at least 3 parts for the header
    if length(parts) < 3
        println("Error: Invalid game string format")
        return nothing
    end

    # Extract moves (everything after the first 3 parts)
    moves = parts[4:end]

    # Create board states for each position
    boards = Vector{Board}(undef, length(moves) + 1)

    # Initial board (after header, before any moves)
    base_state = join(parts[1:3], ";")
    boards[1] = from_game_string(base_state)

    # Build up board states by applying each move
    for (i, move) in enumerate(moves)
        game_state = base_state * ";" * join(moves[1:i], ";")
        boards[i + 1] = from_game_string(game_state)
    end

    current_index = 1  # Start at position 0 (before any moves)

    println("Game loaded with $(length(moves)) moves")
    println("Current position: 0 / $(length(moves))")
    show(boards[current_index]; show_locs=false, simple=false)
    println("ok")

    while true
        command = readline()

        try
            if command == "" || command == "f" || command == "forward"
                # Move forward one move
                if current_index < length(boards)
                    current_index += 1
                    println("\nMove $(current_index - 1): $(moves[current_index - 1])")
                    println("Position: $(current_index - 1) / $(length(moves))")
                    show(boards[current_index]; show_locs=false, simple=false)
                else
                    println("Already at the end of the game")
                end

            elseif command == "b" || command == "back"
                # Move back one move
                if current_index > 1
                    current_index -= 1
                    if current_index == 1
                        println("\nBack to starting position")
                    else
                        println("\nBack to move $(current_index - 1): $(moves[current_index - 1])")
                    end
                    println("Position: $(current_index - 1) / $(length(moves))")
                    show(boards[current_index]; show_locs=false, simple=false)
                else
                    println("Already at the start of the game")
                end

            elseif command == "ff"
                # Move forward 5 moves
                old_index = current_index
                current_index = min(current_index + 5, length(boards))
                if current_index != old_index
                    if current_index == length(boards)
                        println("\nJumped to end of game")
                    else
                        println(
                            "\nJumped forward to move $(current_index - 1): $(moves[current_index - 1])",
                        )
                    end
                    println("Position: $(current_index - 1) / $(length(moves))")
                    show(boards[current_index]; show_locs=false, simple=false)
                else
                    println("Already at the end of the game")
                end

            elseif command == "bb"
                # Move back 5 moves
                old_index = current_index
                current_index = max(current_index - 5, 1)
                if current_index != old_index
                    if current_index == 1
                        println("\nBack to starting position")
                    else
                        println(
                            "\nJumped back to move $(current_index - 1): $(moves[current_index - 1])",
                        )
                    end
                    println("Position: $(current_index - 1) / $(length(moves))")
                    show(boards[current_index]; show_locs=false, simple=false)
                else
                    println("Already at the start of the game")
                end

            elseif command == "0" || command == "start"
                # Jump to start
                if current_index != 1
                    current_index = 1
                    println("\nJumped to starting position")
                    println("Position: 0 / $(length(moves))")
                    show(boards[current_index]; show_locs=false, simple=false)
                else
                    println("Already at the start of the game")
                end

            elseif command == "end"
                # Jump to end
                if current_index != length(boards)
                    current_index = length(boards)
                    println("\nJumped to end of game")
                    println("Position: $(current_index - 1) / $(length(moves))")
                    show(boards[current_index]; show_locs=false, simple=false)
                else
                    println("Already at the end of the game")
                end

            elseif command == "s" || command == "show"
                # Show current board
                if current_index == 1
                    println("\nStarting position")
                else
                    println("\nCurrent move $(current_index - 1): $(moves[current_index - 1])")
                end
                println("Position: $(current_index - 1) / $(length(moves))")
                show(boards[current_index]; show_locs=false, simple=false)

            elseif command == "h" || command == "help" || command == "?"
                println("\nCommands:")
                println("  Enter/f     - Move forward one move")
                println("  b           - Move back one move")
                println("  ff          - Move forward 5 moves")
                println("  bb          - Move back 5 moves")
                println("  0/start     - Jump to start of game")
                println("  end         - Jump to end of game")
                println("  s/show      - Show current board state")
                println("  h/help      - Show this help message")
                println("  q/quit/exit - Exit inspector")

            elseif command == "q" || command == "quit" || command == "exit"
                println("Exiting game inspector")
                break

            else
                println("Unknown command: '$command' (type 'help' for commands)")
            end

            println("ok")

        catch e
            if isa(e, ErrorException)
                println("err " * e.msg)
            else
                io = IOBuffer()
                showerror(io, e)
                println("An error occurred: ", String(take!(io)))
            end
            println("ok")
        end
    end

    return nothing
end