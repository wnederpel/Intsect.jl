path = "C:\\Users\\wolf.nederpel\\Documents\\hivegames"

# Parse a single move line like "1. wL" or "2. bL wL\"
function parse_move(line::AbstractString)
    # Remove move number and period
    m = match(r"^\d+\.\s+(.+)$", line)
    if m === nothing
        return nothing
    end
    return strip(m.captures[1])
end

# Parse a game file and extract moves
function parse_game_file(filepath::String)
    moves = String[]
    lines = readlines(filepath)

    for line in lines
        line = strip(line)
        # Skip empty lines, headers, and result lines
        if isempty(line) ||
            startswith(line, "[") ||
            line == "Draw" ||
            line == "White" ||
            line == "Black" ||
            line == "1-0" ||
            line == "0-1"
            continue
        end

        move = parse_move(line)
        if move !== nothing
            push!(moves, move)
        end
    end

    return moves
end

# Create a canonical representation of a position (list of moves)
# Normalize the second move (index 1) to ignore placement location ONLY if it's exactly 2 moves
function position_key(moves::Vector{String})
    normalized = copy(moves)

    # Only normalize the second move if we have exactly 2 moves
    # If there are more moves, those later moves make the position unique
    if length(normalized) == 2
        second_move = normalized[2]
        # Extract just the piece type (everything before the first space)
        piece_match = match(r"^(\S+)", second_move)
        if piece_match !== nothing
            normalized[2] = piece_match.captures[1]
        end
    end

    return join(normalized, "|")
end

# Find unique starting positions from all games
function extract_unique_positions(game_dir::String, max_moves::Int=12, min_moves::Int=6)
    # Store all games first
    all_games = Vector{Tuple{Int,Vector{String}}}()

    # Get all game files
    game_files = filter(f -> endswith(f, ".pgn"), readdir(game_dir; join=true))

    println("Found $(length(game_files)) game files")
    println("Extracting unique starting positions (max $max_moves moves)...\n")

    # Parse all games
    for (game_idx, filepath) in enumerate(game_files)
        moves = parse_game_file(filepath)
        if !isempty(moves) && length(moves) >= min_moves
            push!(all_games, (game_idx, moves))
        end
    end

    # Helper function to check if moves1 is a prefix of moves2
    function is_prefix(moves1::Vector{String}, moves2::Vector{String})
        if length(moves1) >= length(moves2)
            return false
        end
        for i in 1:length(moves1)
            if moves1[i] != moves2[i]
                return false
            end
        end
        return true
    end

    # Helper function to try adding a game
    function try_add_game(
        game_idx::Int, moves::Vector{String}, result_positions::Vector{Tuple{Int,Vector{String}}}
    )
        # Start with minimum moves and try to find a unique prefix
        for n_moves in min_moves:min(length(moves), max_moves)
            prefix = moves[1:n_moves]
            key = position_key(prefix)

            # Check if this prefix is unique among all other games at any length
            is_unique = true
            for (other_idx, other_result) in result_positions
                if other_idx != game_idx
                    other_key = position_key(other_result)
                    if key == other_key
                        is_unique = false
                        break
                    end
                end
            end

            if is_unique
                push!(result_positions, (game_idx, prefix))
                println("Game $game_idx: Unique position with $n_moves moves")
                return n_moves
            end
        end

        # Use maximum available moves as fallback
        n_moves = min(length(moves), max_moves)
        prefix = moves[1:n_moves]
        push!(result_positions, (game_idx, prefix))
        println("Game $game_idx: Added with $n_moves moves (may not be unique)")
        return n_moves
    end

    # Now find unique prefixes for each game
    result_positions = Vector{Tuple{Int,Vector{String}}}()

    for (game_idx, moves) in all_games
        # Check if any already-added game has moves that are a prefix of current game
        games_to_readd = Vector{Tuple{Int,Vector{String}}}()

        # Try to add the game, see how many moves are used
        n_moves = try_add_game(game_idx, moves, result_positions)
        moves_used = moves[1:n_moves]

        indices_to_delete = Int[]
        for i in length(result_positions):-1:1
            (existing_idx, existing_prefix) = result_positions[i]
            if is_prefix(existing_prefix, moves_used)
                # Remove this game and mark for re-adding
                push!(
                    games_to_readd,
                    (existing_idx, all_games[findfirst(x -> x[1] == existing_idx, all_games)][2]),
                )
                push!(indices_to_delete, i)
                println("Game $existing_idx: Removed (is prefix of Game $game_idx), will re-add")
            end
        end
        deleteat!(result_positions, reverse(indices_to_delete))

        # Re-add the removed games
        for (readd_idx, readd_moves) in games_to_readd
            try_add_game(readd_idx, readd_moves, result_positions)
        end
    end

    # Convert to output format
    unique_positions = Dict{String,Vector{String}}()
    position_order = String[]

    for (game_idx, prefix) in result_positions
        key = position_key(prefix)
        unique_positions[key] = prefix
        push!(position_order, key)
    end

    return unique_positions, position_order
end

# Main execution
println("="^60)
println("Extracting Unique Starting Positions from Hive Games")
println("="^60)

unique_positions, position_order = extract_unique_positions(path, 120, 2)

# Save to file - simple format (semicolon-separated moves)
output_file = joinpath("C:\\intsect", "starting_positions.txt")
open(output_file, "w") do io
    for key in position_order
        moves = unique_positions[key]
        if !isempty(moves)
            println(io, join(moves, ";"))
        end
    end
end

println("\n" * "="^60)
println("Results saved to: $output_file")
println("="^60)
