"""
    faceoff(engine1_path, engine2_path; time_limit=1.0, debug=false)

Plays two UHP engines against each other until one wins.
- engine1_path: Path to first engine executable
- engine2_path: Path to second engine executable  
- time_limit: Thinking time per move in seconds (default: 1.0)
- debug: Print debug statements (default: false)

Returns the result (to be implemented).
"""
function faceoff(engine1_path::String, engine2_path::String; time_limit=2, debug=false)
    depth = 3
    println("contestant 1: $engine1_path")
    println("contestant 2: $engine2_path")
    println("ready..")
    println("fight!")

    is_source1 = engine1_path == "engines\\source"
    is_source2 = engine2_path == "engines\\source"
    is_source = [is_source1, is_source2]

    # Start both engines
    debug && println("[DEBUG] Starting engine 1...")
    if !is_source1
        engine1 = open(`$engine1_path`, "r+")
    else
        engine1 = nothing
    end
    debug && println("[DEBUG] Engine 1 started")
    debug && println("[DEBUG] Starting engine 2...")
    if !is_source2
        engine2 = open(`$engine2_path`, "r+")
    else
        engine2 = nothing
    end
    debug && println("[DEBUG] Engine 2 started")

    # Read initial greeting from both engines until "ok"
    debug && println("[DEBUG] Reading initial greetings...")
    for (i, engine) in enumerate([engine1, engine2])
        if is_source[i]
            debug && println("[DEBUG] Engine $i is source")
        else
            debug && println("[DEBUG] Reading greeting from engine $i")
            while !eof(engine)
                line = readline(engine)
                debug && println("[DEBUG] Engine $i: $line")
                if startswith(line, "ok")
                    break
                end
            end
        end
    end
    debug && println("[DEBUG] Greetings complete")

    # Start a new game - Base+MLP is standard Hive with all expansions
    game_state = "Base+MLP;InProgress;white[1]"
    debug && println("[DEBUG] Sending newgame commands...")
    boards = Board[from_game_string(game_state), from_game_string(game_state)]
    for (i, engine) in enumerate([engine1, engine2])
        debug && println("[DEBUG] Sending newgame to engine $i: $game_state")
        if is_source[i]
            # see boards.
            debug && println("[DEBUG] Engine $i response: ok")
        else
            write(engine, "newgame $game_state\n")
            flush(engine)
            # Wait for ok
            while !eof(engine)
                line = readline(engine)
                debug && println("[DEBUG] Engine $i response: $line")
                if startswith(line, "ok")
                    break
                end
            end
        end
    end
    debug && println("[DEBUG] Newgame commands complete")

    println("Game started: $game_state")
    move_number = 0
    current_engine = engine1
    current_engine_i = 1
    current_color = "White"
    other_engine = engine2
    other_engine_i = 2
    move_history = String[]

    # Play until game over
    while true
        move_number += 1
        debug && println("[DEBUG] Move $move_number starting, $current_color to play")

        # Ask current engine for best move with time limit
        debug && println("[DEBUG] Requesting bestmove from $current_color")
        if !is_source[current_engine_i]
            write(current_engine, "bestmove time 00:00:0$time_limit\n")
            flush(current_engine)
            debug && println("[DEBUG] Bestmove request sent, waiting for response...")

            # Read the best move
            best_move = ""
            while !eof(current_engine)
                line = strip(readline(current_engine))
                debug && println("[DEBUG] $current_color response: $line")
                if startswith(line, "ok")
                    break
                else
                    best_move = line
                end
            end
        else
            board = boards[current_engine_i]
            debug && println("[DEBUG] Bestmove request sent, waiting for response...")
            action = get_best_move(board; time_limit_s=time_limit, debug=false)
            best_move = move_string_from_action(board, action)
            debug && println("[DEBUG] $current_color response: $best_move")
            debug && println("[DEBUG] $current_color response: ok")
        end
        debug && println("[DEBUG] Bestmove received: $best_move")

        if isempty(best_move)
            println("$current_color has no valid moves?!")
            break
        end

        println("Move $move_number ($current_color): $best_move")
        push!(move_history, best_move)

        # Update game state
        game_state = game_state * ";" * best_move

        # Send the move to both engines
        debug && println("[DEBUG] Sending play command to both engines: $best_move")
        for engine in [current_engine, other_engine]
            engine_i = engine == engine1 ? 1 : 2
            debug && println("[DEBUG] Sending play to engine $engine_i")
            if !is_source[engine_i]
                write(engine, "play $best_move\n")
                flush(engine)
                # Wait for ok
                while !eof(engine)
                    line = readline(engine)
                    debug && println("[DEBUG] Engine $engine_i play response: $line")
                    if startswith(line, "ok")
                        break
                    end
                end
            else
                board = boards[engine_i]
                do_action(board, best_move)
                debug && println("[DEBUG] Engine $engine_i play response: ok")
            end
        end
        debug && println("[DEBUG] Play commands complete")

        show(board)

        # Check game state by parsing with our own board
        debug && println("[DEBUG] Checking game state: $game_state")
        check_board = from_game_string(game_state)
        debug && println("[DEBUG] Game over: $(check_board.gameover)")

        if check_board.gameover
            println("\n=== Game Over ===")
            if check_board.victor == WHITE
                println("Winner: White (Engine 1)")
                if !is_source1
                    close(engine1)
                end
                if !is_source2
                    close(engine2)
                end
                return 1  # Engine 1 wins
            elseif check_board.victor == BLACK
                println("Winner: Black (Engine 2)")
                if !is_source1
                    close(engine1)
                end
                if !is_source2
                    close(engine2)
                end
                return 2  # Engine 2 wins
            else
                println("Draw!")
                if !is_source1
                    close(engine1)
                end
                if !is_source2
                    close(engine2)
                end
                return 0  # Draw
            end
        end

        # Switch players
        if current_engine == engine1
            current_engine = engine2
            current_engine_i = 2
            other_engine = engine1
            current_color = "Black"
        else
            current_engine = engine1
            current_engine_i = 1
            other_engine = engine2
            current_color = "White"
        end
    end

    if !is_source1
        close(engine1)
    end
    if !is_source2
        close(engine2)
    end
    return nothing
end

function run_arena(; debug=false)
    engines = YAML.load_file("engines/engines.yaml")
    intsect_engines = engines["intsect"]
    existing_engines = engines["existing_engines"]

    engines_dir = "engines"

    # Resolve paths relative to engines directory
    intsect_paths = [joinpath(engines_dir, engine) for engine in intsect_engines]
    existing_paths = [joinpath(engines_dir, engine) for engine in existing_engines]

    for i in 1:(length(intsect_paths) - 1)
        older_intsect = intsect_paths[i]
        newer_intsect = intsect_paths[i + 1]
        res = faceoff(older_intsect, newer_intsect; debug=debug)
    end
    latest_intsect = intsect_paths[end]
    for existing in existing_paths
        res = faceoff(latest_intsect, existing; debug=debug)
    end
    if length(intsect_paths) > 1
        runner_up_intsect = intsect_paths[end - 1]
        for existing in existing_paths
            res = faceoff(runner_up_intsect, existing; debug=debug)
        end
    end

    return nothing
end