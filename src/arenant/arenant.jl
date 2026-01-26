
"""
    faceoff(engine1_path, engine2_path; time_limit=1.0)

Plays two UHP engines against each other until one wins.
- engine1_path: Path to first engine executable
- engine2_path: Path to second engine executable  
- time_limit: Thinking time per move in seconds (default: 1.0)

Returns the result (to be implemented).
"""
function faceoff(engine1_path::String, engine2_path::String; time_limit=1.0)
    # Start both engines
    engine1 = open(`$engine1_path`, "r+")
    engine2 = open(`$engine2_path`, "r+")

    # Read initial greeting from both engines until "ok"
    for engine in [engine1, engine2]
        while !eof(engine)
            line = readline(engine)
            if startswith(line, "ok")
                break
            end
        end
    end

    # Start a new game - Base+MLP is standard Hive with all expansions
    game_state = "Base+MLP;InProgress;white[1]"

    for engine in [engine1, engine2]
        write(engine, "newgame $game_state\n")
        flush(engine)
        # Wait for ok
        while !eof(engine)
            line = readline(engine)
            if startswith(line, "ok")
                break
            end
        end
    end

    println("Game started: $game_state")
    move_number = 0
    current_engine = engine1
    current_color = "White"
    other_engine = engine2
    move_history = String[]

    # Play until game over
    while true
        move_number += 1

        # Ask current engine for best move with time limit
        time_ms = Int(round(time_limit * 1000))
        write(current_engine, "bestmove time $time_ms\n")
        flush(current_engine)

        # Read the best move
        best_move = ""
        while !eof(current_engine)
            line = strip(readline(current_engine))
            if startswith(line, "bestmove")
                parts = split(line)
                if length(parts) >= 2
                    best_move = parts[2]
                end
            elseif startswith(line, "ok")
                break
            end
        end

        if isempty(best_move) || best_move == "pass"
            println("$current_color has no valid moves or passed!")
            break
        end

        println("Move $move_number ($current_color): $best_move")
        push!(move_history, best_move)

        # Update game state
        game_state = game_state * ";" * best_move

        # Send the move to both engines
        for engine in [current_engine, other_engine]
            write(engine, "play $best_move\n")
            flush(engine)
            # Wait for ok
            while !eof(engine)
                line = readline(engine)
                if startswith(line, "ok")
                    break
                end
            end
        end

        # Check game state by parsing with our own board
        board = from_game_string(game_state)

        if board.gameover
            println("\n=== Game Over ===")
            if board.victor == WHITE
                println("Winner: White (Engine 1)")
                close(engine1)
                close(engine2)
                return 1  # Engine 1 wins
            elseif board.victor == BLACK
                println("Winner: Black (Engine 2)")
                close(engine1)
                close(engine2)
                return 2  # Engine 2 wins
            else
                println("Draw!")
                close(engine1)
                close(engine2)
                return 0  # Draw
            end
        end

        # Switch players
        if current_engine == engine1
            current_engine = engine2
            other_engine = engine1
            current_color = "Black"
        else
            current_engine = engine1
            other_engine = engine2
            current_color = "White"
        end
    end

    close(engine1)
    close(engine2)
    return nothing
end

function run_arena()
    engines = YAML.load_file("engines/engines.yaml")
    intsect_engines = engines["intsect"]
    existing_engines = engines["existing_engines"]

    for i in 1:(length(intsect_engines) - 1)
        older_intsect = intsect_engines[i]
        newer_intsect = intsect_engines[i + 1]
        res = faceoff(older_intsect, newer_intsect)
    end
    latest_intsect = intsect_engines[end]
    for existing in existing_engines
        res = faceoff(latest_intsect, existing)
    end
    if length(intsect_engines) > 1
        runner_up_intsect = intsect_engines[end - 1]
        for existing in existing_engines
            res = faceoff(latest_intsect, existing)
        end
    end

    return nothing
end