"""
    play_one_match(engine1_path, engine2_path, time_limit; starting_position="", debug=false)

Plays two UHP engines against each other from a given starting position until one wins.
- engine1_path: Path to first engine executable
- engine2_path: Path to second engine executable  
- time_limit: Thinking time per move in seconds
- starting_position: Starting moves separated by semicolons (default: empty for new game)
- debug: Print debug statements (default: false)

Returns 1 if engine1 wins, 2 if engine2 wins, 0 for draw.
"""
function play_one_match(
    engine1_path::String,
    engine2_path::String,
    time_limit_s::Real;
    starting_position="",
    debug=false,
)
    engine1_name = split(basename(engine1_path), '.')[1]
    engine2_name = split(basename(engine2_path), '.')[1]
    println("White: $engine1_name vs Black: $engine2_name")
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
    if isempty(starting_position)
        game_state = "Base+MLP;InProgress;white[1]"
    else
        game_state = "Base+MLP;InProgress;white[1];" * starting_position
    end
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

    move_number = 0
    current_engine = engine1
    current_engine_i = 1
    current_color = "White"
    other_engine = engine2
    move_history = String[]

    # Play until game over
    while true
        move_number += 1
        debug && println("[DEBUG] Move $move_number starting, $current_color to play")

        # Ask current engine for best move with time limit
        debug && println("[DEBUG] Requesting bestmove from $current_color")
        if !is_source[current_engine_i]
            write(current_engine, "bestmove time 00:00:0$time_limit_s\n")
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
            action = get_best_move(board; time_limit_s=time_limit_s, debug=false)
            best_move = move_string_from_action(board, action)
            debug && println("[DEBUG] $current_color response: $best_move")
            debug && println("[DEBUG] $current_color response: ok")
        end
        debug && println("[DEBUG] Bestmove received: $best_move")

        if isempty(best_move)
            break
        end

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
                    # read the game over state from the game string
                    game_state = split(line, ";")[2]
                    if game_state != "WhiteWins" &&
                        game_state != "BlackWins" &&
                        game_state != "Draw"
                        continue
                    end
                    println("=== Game Over ===")
                    println("Final game state: $line")
                    if game_state == "WhiteWins"
                        println("Winner: White ($engine1_name)\n")
                        if !is_source1
                            close(engine1)
                        end
                        if !is_source2
                            close(engine2)
                        end
                        return 1  # Engine 1 wins
                    elseif game_state == "BlackWins"
                        println("Winner: Black ($engine2_name)\n")
                        if !is_source1
                            close(engine1)
                        end
                        if !is_source2
                            close(engine2)
                        end
                        return 2  # Engine 2 wins
                    else
                        println("Draw between $engine1_name and $engine2_name\n")
                        if !is_source1
                            close(engine1)
                        end
                        if !is_source2
                            close(engine2)
                        end
                        return 0  # Draw
                    end
                end
            else
                board = boards[engine_i]
                do_action(board, best_move)
                debug && println("[DEBUG] Engine $engine_i play response: ok")
            end
        end
        debug && println("[DEBUG] Play commands complete")

        debug && show(board)

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

"""
    read_positions(filepath::String)

Reads starting positions from a file where each line contains moves separated by semicolons.
Returns a vector of position strings.
"""
function read_positions(filepath::String)
    positions = String[]
    if !isfile(filepath)
        @warn "Position file not found: $filepath"
        return positions
    end

    open(filepath, "r") do io
        for line in eachline(io)
            line = strip(line)
            if !isempty(line)
                push!(positions, line)
            end
        end
    end

    return positions
end

"""
    faceoff(engine1_path, engine2_path; time_limit=1.0, positions_file="unique_positions.txt", debug=false)

Plays two engines against each other through all starting positions, with each engine playing both colors.
- engine1_path: Path to first engine executable
- engine2_path: Path to second engine executable
- time_limit: Thinking time per move in seconds (default: 1.0)
- positions_file: File containing starting positions (default: "unique_positions.txt")
- debug: Print debug statements (default: false)

Returns a summary of results.
"""
function faceoff(
    engine1_path::String,
    engine2_path::String;
    time_limit_s=1,
    positions_file="unique_positions.txt",
    debug=false,
)
    engine1_name = split(basename(engine1_path), '.')[1]
    engine2_name = split(basename(engine2_path), '.')[1]
    println("\n" * "="^70)
    println("Faceoff between:")
    println("Engine 1: $engine1_name")
    println("Engine 2: $engine2_name")
    println("="^70 * "\n")
    # Read starting positions
    positions = read_positions(positions_file)

    # Track results
    results = Dict(
        "engine1_as_white" => 0,
        "engine2_as_white" => 0,
        "draws" => 0,
        "total_games" => 0,
        "errors" => 0,
    )

    errors_log = String[]

    # Play each position with both color assignments
    for (pos_idx, position) in enumerate(positions)
        println("Position $pos_idx")
        println("Starting from $position")

        # Game 1: Engine1 as White, Engine2 as Black
        try
            result1 = play_one_match(
                engine1_path, engine2_path, time_limit_s; starting_position=position, debug=false
            )

            if result1 == 1
                results["engine1_as_white"] += 1
            elseif result1 == 2
                results["engine2_as_white"] += 1  # Engine2 won as Black
            else
                results["draws"] += 1
            end
            results["total_games"] += 1
        catch e
            e isa InterruptException && rethrow()
            debug && rethrow()
            results["errors"] += 1
            error_msg = "Position $pos_idx, Game 1 (Engine1 White): $(sprint(showerror, e))"
            push!(errors_log, error_msg)
            @warn error_msg
        end

        # Game 2: Engine2 as White, Engine1 as Black
        try
            result2 = play_one_match(
                engine2_path, engine1_path, time_limit_s; starting_position=position, debug=false
            )

            if result2 == 1
                results["engine2_as_white"] += 1
            elseif result2 == 2
                results["engine1_as_white"] += 1  # Engine1 won as Black
            else
                results["draws"] += 1
            end
            results["total_games"] += 1
        catch e
            e isa InterruptException && rethrow()
            debug && rethrow()
            results["errors"] += 1
            error_msg = "Position $pos_idx, Game 2 (Engine2 White): $(sprint(showerror, e))"
            push!(errors_log, error_msg)
            @warn error_msg
        end
    end

    # Print final summary
    println("\n" * "="^70)
    println("RESULTS")
    println("="^70)
    println("Total games played: $(results["total_games"])")
    println("Total positions: $(length(positions))")
    println("Errors encountered: $(results["errors"])")
    println()

    engine1_total = results["engine1_as_white"]
    engine2_total = results["engine2_as_white"]
    draws = results["draws"]
    total = results["total_games"]

    if total > 0
        println("Engine 1 ($engine1_name):")
        println("  Wins: $engine1_total / $total ($(round(engine1_total/total*100, digits=1))%)")
        println()
        println("Engine 2 ($engine2_name):")
        println("  Wins: $engine2_total / $total ($(round(engine2_total/total*100, digits=1))%)")
        println()
        println("Draws: $draws / $total ($(round(draws/total*100, digits=1))%)")
    else
        println("No games completed successfully")
    end

    if !isempty(errors_log)
        println("\n" * "="^70)
        println("ERRORS LOG")
        println("="^70)
        for error_msg in errors_log
            println(error_msg)
        end
    end
    println("="^70)

    return results
end

function run_arena(; debug=false, time_limit_s=0.05)
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
        faceoff(older_intsect, newer_intsect; time_limit_s=time_limit_s, debug=debug)
    end
    latest_intsect = intsect_paths[end]
    for existing in existing_paths
        faceoff(latest_intsect, existing; time_limit_s=time_limit_s, debug=debug)
    end
    if length(intsect_paths) > 1
        runner_up_intsect = intsect_paths[end - 1]
        for existing in existing_paths
            faceoff(runner_up_intsect, existing; time_limit_s=time_limit_s, debug=debug)
        end
    end

    return nothing
end