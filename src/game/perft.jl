function perft(; output=true)
    perft(5; output=output)
    return nothing
end

function perft(n; output=true, type=MLPGame, game_string="Base+MLP;InProgress;white[1]")
    # https://github.com/jonthysell/Mzinga/wiki/Perft
    board = from_game_string(game_string)
    if output
        show(board; simple=false)
    end
    for depth in 1:n
        nodes, time_taken, memory_allocated, gc_time, _ = @timed perft(depth, board)
        if output
            println("Perft($depth) \t = $(format_with_dots(nodes))")
            kilo_nodes = nodes / 1000
            println("KN/S \t\t = $(format_with_dots(Int.(round(kilo_nodes / time_taken))))")
            println("memory per node  = $(round(memory_allocated / nodes, digits=2)) bytes")
            println("gc time \t = $(round(gc_time*100))%")
            println("total time \t = $(round(time_taken, digits=2)) seconds")
            println()
        end
    end
    return nothing
end

function perft(depth::Integer, board)::Integer
    if depth == 0
        return 1
    end
    if depth == 1
        # Not needed to allocate here, use a global valid move buffer,
        # Here you can just read the action_index.
        @no_escape PERFT_BUFFER[depth] begin
            move_buffer = @alloc(eltype(Int), VALID_BUFFER_SIZE)
            validactions!(board, move_buffer)
        end
        return board.action_index - 1
    end

    nodes = 0

    @no_escape PERFT_BUFFER[depth] begin
        move_buffer = @alloc(eltype(Int), VALID_BUFFER_SIZE)

        validactions!(board, move_buffer)
        for action_i in 1:(board.action_index - 1)
            action_as_index = move_buffer[action_i]

            do_action(board, action_as_index)

            nodes += perft(depth - 1, board)
            undo(board)
        end
    end

    return nodes
end

function format_with_dots(n)
    s = string(n)
    len = length(s)
    parts = []

    for i in len:-3:1
        start_index = max(i - 2, 1)
        push!(parts, s[start_index:i])
    end

    return join(reverse(parts), '.')
end

const NOKAMUTE_PATH::String = "C:\\intsect\\external\\nokamute.exe"
const MZINGA_PATH::String = "C:\\intsect\\external\\MzingaEngine.exe"

"""
    nokamute_valid_moves(game_string; exe=NOKAMUTE_PATH)

Run `nokamute.exe validmoves "GAMESTRING"` and parse moves.
Returns a Set{String} of valid moves.
"""
function external_valid_moves(game_string::AbstractString; exe::AbstractString=NOKAMUTE_PATH)
    # Start nokamute.exe interactively
    p = open(`$exe`, "r+")
    # Read initial greeting lines
    while !eof(p)
        line = readline(p)
        if startswith(line, "ok")
            break
        end
    end

    # Parse game type from gamestring
    write(p, "newgame $game_string\n")
    flush(p)
    # Read until ok
    while !eof(p)
        line = readline(p)
        if startswith(line, "ok")
            break
        end
    end

    # Request validmoves
    write(p, "validmoves\n")
    flush(p)
    moves = Set{String}()
    # Read moves until ok
    while !eof(p)
        line = strip(readline(p))
        if line == "ok"
            break
        end
        isempty(line) && continue
        moves_on_line = strip.(split(line, ";"))
        for m in moves_on_line
            push!(moves, m)
        end
    end
    close(p)
    return moves
end

"""
    compare_valid_moves_report(board, game_string; exe)

Compares your valid moves to Nokamute's and prints a report.
"""
function compare_valid_moves_report(board, game_string, my_nodes, their_nodes; exe=NOKAMUTE_PATH)
    # Your moves
    buf = similar_move_buffer()
    your_indices = collect(list_actions!(board, buf))
    your_moves = Set(move_to_str(board, i) for i in your_indices)
    if length(your_moves) != my_nodes
        show(board)
        println(
            "Warning: your reported perft count $my_nodes does not match your valid move count $(length(your_moves))",
        )
        duplicates_moves = []
        all_moves = [move_to_str(board, i) for i in your_indices]
        for move in all_moves
            if count(==(move), all_moves) > 1
                push!(duplicates_moves, move)
            end
        end
        println("duplicate moves: ", duplicates_moves)
    end

    # Nokamute moves
    nok_moves = external_valid_moves(game_string; exe=exe)
    if length(nok_moves) != their_nodes
        println(
            "Warning: Nokamute reported perft count $their_nodes does not match its valid move count $(length(nok_moves))",
        )
    end

    missing = setdiff(nok_moves, your_moves)
    extra = setdiff(your_moves, nok_moves)

    println("--- Valid Moves Comparison Report ---")
    if !isempty(missing)
        println("These were in Nokamute that you missed:")
        for m in missing
            println("  $m")
        end
    else
        println("No missing moves from Nokamute.")
    end
    if !isempty(extra)
        println("You have these while Nokamute did not:")
        for m in extra
            println("  $m")
        end
    else
        println("No extra moves compared to Nokamute.")
    end
    println("-------------------------------------")

    # Compare Nokamute vs Mzinga
    mzinga_moves = external_valid_moves(game_string; exe=MZINGA_PATH)
    nok_not_mzinga = setdiff(nok_moves, mzinga_moves)
    mzinga_not_nok = setdiff(mzinga_moves, nok_moves)
    println("--- Nokamute vs Mzinga Valid Moves ---")
    if !isempty(nok_not_mzinga)
        println("Nokamute has these moves that Mzinga does not:")
        for m in nok_not_mzinga
            println("  $m")
        end
    else
        println("No moves unique to Nokamute.")
    end
    if !isempty(mzinga_not_nok)
        println("Mzinga has these moves that Nokamute does not:")
        for m in mzinga_not_nok
            println("  $m")
        end
    else
        println("No moves unique to Mzinga.")
    end
    return println("-------------------------------------")
end
using Intsect

"""
    nokamute_perft_counts(game_string, maxdepth; exe="C:\\hive\\nokamute.exe")

Run `nokamute.exe perft "GAMESTRING"` and parse rows:
    depth  count  time  kn/s
Returns Dict{Int,Int} of depth=>count, stopping at maxdepth.
"""
function nokamute_perft_counts(
    game_string::AbstractString, maxdepth::Integer; exe::AbstractString=NOKAMUTE_PATH
)
    stdout_pipe = Pipe()
    # start process, stream stdout into our pipe, don't wait
    p = run(pipeline(`$exe perft $game_string`; stdout=stdout_pipe); wait=false)
    close(stdout_pipe.in)  # we only read

    counts = Dict{Int,Int}()
    for line in eachline(stdout_pipe)
        # skip headers and empty lines
        s = strip(line)
        isempty(s) && continue
        startswith(s, "depth") && continue
        # match leftmost "depth  count"
        if (m = match(r"^\s*(\d+)\s+(\d+)\b", s)) !== nothing
            d = parse(Int, m.captures[1])
            c = parse(Int, m.captures[2])
            counts[d] = c
            if d >= maxdepth
                try
                    kill(p)  # we got what we need
                catch
                end
                break
            end
        end
    end
    # drain and finish
    try
        wait(p)
    catch
        # ignore non-zero exit after kill
    end
    return counts
end

# Convert your internal action index to a Nokamute move string.
# You MUST implement this to match what `do_action(board, ::String)` accepts.
move_to_str(board, action_index) = move_string_from_action(board, ALL_ACTIONS[action_index])

# Allocate a temporary move buffer. Use your own buffer scheme if needed.
similar_move_buffer(::Type{T}=Int) where {T} = Vector{T}(undef, 500)

# Enumerate legal action indices using your existing API
function list_actions!(board, buf::Vector{Int})
    validactions!(board, buf)
    return view(buf, 1:(board.action_index - 1))  # 1-based slice of valid indices
end

"""
    diff_perft!(board, game_string, depth; exe, stop_on_first=true) -> Bool

Compares your perft vs Nokamute at `depth`. If mismatch and depth>1,
recurses on the first child that also mismatches, until depth==1.
Returns true on match, false if a mismatch path was found (and printed).
"""
function diff_perft!(
    board, game_string::AbstractString, depth::Integer; exe=NOKAMUTE_PATH, stop_on_first::Bool=true
)
    # your count
    my_nodes = perft(depth, board)

    # nokamute counts up to `depth`
    nk = nokamute_perft_counts(game_string, depth; exe)
    haskey(nk, depth) || error("Nokamute output missing depth=$depth")

    their_nodes = nk[depth]
    if my_nodes == their_nodes
        println("OK depth $depth => $my_nodes")
        return true
    end

    println("MISMATCH depth $depth => mine=$my_nodes, nokamute=$their_nodes")
    if depth == 1
        println("Gamestring at error: $game_string")
        compare_valid_moves_report(board, game_string, my_nodes, their_nodes; exe=exe)
        return false  # cannot drill
    end

    # Drill: enumerate children on *your* generator, compare each child’s perft(depth-1)
    buf = similar_move_buffer()
    for act in list_actions!(board, buf)
        child_move_str = move_to_str(board, act)  # must reflect the move we just made
        do_action(board, act)
        child_nodes = perft(depth - 1, board)

        child_gs = string(game_string, ";", child_move_str)
        nk_child = nokamute_perft_counts(child_gs, depth - 1; exe)
        theirs_child = Base.get(nk_child, depth - 1, nothing)
        if theirs_child === nothing
            error("Nokamute child missing depth=$(depth-1) for move $child_move_str")
        end

        if child_nodes != theirs_child
            println(
                " -> first diverging move: $child_move_str at depth $(depth-1)  mine=$child_nodes  nok=$theirs_child",
            )
            check_draw(board)
            show(board; simple=false)
            ok = diff_perft!(board, child_gs, depth - 1; exe, stop_on_first=stop_on_first)
            undo(board)
            return ok  # stop at first mismatch
        end
        undo(board)
    end

    # If we got here, none of the children mismatched. That means the mismatch
    # is due to move counting at root without a child mismatch, which implies a bug in
    # either child enumeration or undo symmetry. Report and stop.
    println(
        "No child diffs found, but root diff exists. Check root move gen / undo / move_to_str mapping.",
    )
    return false
end

"""
    verify_perft(game_string, maxdepth; type=MLPGame, exe, stop_on_first=true)

Replays the prefix from `game_string` on a fresh board, then for d=1..maxdepth:
- compare your perft vs Nokamute
- stop at first mismatch after drilling to depth 1
"""
function verify_perft(
    game_string::AbstractString,
    maxdepth::Integer;
    type=MLPGame,
    exe=NOKAMUTE_PATH,
    stop_on_first::Bool=true,
)::Bool
    board = handle_newgame_command(type)

    # apply prefix moves embedded in the game string (your format already supports this)
    parts = split(game_string, ';')
    if length(parts) > 3
        for mv in parts[4:end]
            isempty(mv) && continue
            do_action(board, mv)
        end
    end
    # show(board; simple=false)
    for d in 1:maxdepth
        println("=== depth $d ===")
        ok = diff_perft!(board, game_string, d; exe, stop_on_first=stop_on_first)
        if !ok
            return false
        end
    end
    println("All depths 1..$maxdepth matched.")
    return true
end