"""
Match Player - Play out AI vs AI matches with interactive controls

This module provides functionality to watch AI agents play against each other,
with controls to:
- Advance moves one at a time (press Enter)
- Reset to predefined starting positions (0-9)
- Play out multiple plies at once (f=4 ply, ff=8 ply)
"""

"""
    create_starting_positions()

Create 10 predefined starting positions indexed 0-9.
Position 0 is an empty board.
Positions 1-9 have various piece configurations for variety.
"""
function create_starting_positions(gametype::Type{T}) where {T<:Gametype}
    positions = Vector{Board}(undef, 10)

    # Position 0: Empty board
    positions[1] = handle_newgame_command(gametype)

    # Position 1: One piece each
    positions[2] = handle_newgame_command(gametype)
    do_action(positions[2], action_from_move_string(positions[2], "wA1"))
    do_action(positions[2], action_from_move_string(positions[2], "bA1 -wA1"))

    # Position 2: Two pieces each
    positions[3] = handle_newgame_command(gametype)
    do_action(positions[3], action_from_move_string(positions[3], "wA1"))
    do_action(positions[3], action_from_move_string(positions[3], "bA1 -wA1"))
    do_action(positions[3], action_from_move_string(positions[3], "wS1 wA1/"))
    do_action(positions[3], action_from_move_string(positions[3], "bS1 /bA1"))

    # Position 3: Queens placed (move 7 for white)
    positions[4] = handle_newgame_command(gametype)
    do_action(positions[4], action_from_move_string(positions[4], "wA1"))
    do_action(positions[4], action_from_move_string(positions[4], "bA1 -wA1"))
    do_action(positions[4], action_from_move_string(positions[4], "wS1 wA1/"))
    do_action(positions[4], action_from_move_string(positions[4], "bS1 /bA1"))
    do_action(positions[4], action_from_move_string(positions[4], "wB1 wA1-"))
    do_action(positions[4], action_from_move_string(positions[4], "bB1 -bA1"))
    do_action(positions[4], action_from_move_string(positions[4], "wQ wA1\\"))
    do_action(positions[4], action_from_move_string(positions[4], "bQ \\bA1"))

    positions[5] = handle_newgame_command(gametype)

    positions[6] = handle_newgame_command(gametype)

    positions[7] = handle_newgame_command(gametype)

    positions[8] = handle_newgame_command(gametype)

    positions[9] = handle_newgame_command(gametype)

    positions[10] = handle_newgame_command(gametype)

    return positions
end

"""
    play_next_move!(board::Board, best_move_func)

Execute one move using the provided best_move function.
Returns true if move was executed, false if game is over.
"""
function play_next_move!(board::Board, best_move_func)
    if board.gameover
        println("\n=== Game Over ===")
        if board.victor == WHITE
            println("White wins!")
        elseif board.victor == BLACK
            println("Black wins!")
        else
            println("Draw!")
        end
        return false
    end

    current_player = board.current_color == WHITE ? "White" : "Black"
    println("\n--- $current_player to move (ply $(board.ply)) ---")

    action = best_move_func(board)
    show(action, board)
    do_action(board, action)
    show(board; show_locs=true, simple=false)

    return true
end

"""
    play_n_plies!(board::Board, best_move_func, n::Int)

Execute n plies (half-moves) using the provided best_move function.
"""
function play_n_plies!(board::Board, best_move_func, n::Int)
    for i in 1:n
        if !play_next_move!(board, best_move_func)
            println("Game ended after $i plies")
            break
        end
    end
end

"""
    start_match_player(best_move_func; gametype::Type{<:Gametype}=MLPGame, starting_position::Int=0)

Start the interactive match player.

Parameters:
- `best_move_func`: Function that takes a Board and returns an Action (best move to play)
- `gametype`: Game type to use (default: MLPGame - full game with all pieces)
- `starting_position`: Which starting position to begin with (0-9, default: 0)

Commands:
- Press Enter: Play next move
- 0-9: Reset to starting position N
- f: Play out 4 plies
- ff: Play out 8 plies
- show: Display current board
- help: Show this help message
- q/quit/exit: Exit the match player
"""
function start_match_player(
    best_move_func; gametype::Type{<:Gametype}=MLPGame, starting_position::Int=0
)
    println("=== Match Player ===")
    println("AI vs AI with interactive controls")
    println("Type 'help' for commands")
    println()

    # Create starting positions
    positions = create_starting_positions(gametype)

    # Initialize board to chosen starting position
    if starting_position < 0 || starting_position > 9
        println("Invalid starting position $starting_position, using 0")
        starting_position = 0
    end

    # Deep copy the starting position so we can reset to it
    board = deepcopy(positions[starting_position + 1])
    current_position_index = starting_position

    println("Starting from position $starting_position")
    show(board; show_locs=true, simple=true)
    println("ok")

    while true
        command = readline()

        if command == "" || command == "next" || command == "n"
            # Play next move
            play_next_move!(board, best_move_func)

        elseif command in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
            # Reset to starting position
            pos_index = parse(Int, command)
            board = deepcopy(positions[pos_index + 1])
            current_position_index = pos_index
            println("\nReset to starting position $pos_index")
            show(board; show_locs=true, simple=true)

        elseif command == "f"
            # Play out 4 plies
            println("\n=== Playing 5 plies ===")
            play_n_plies!(board, best_move_func, 5)

        elseif command == "ff"
            # Play out 8 plies
            println("\n=== Playing 10 plies ===")
            play_n_plies!(board, best_move_func, 10)

        elseif command == "show" || command == "s"
            # Display current board
            show(board; show_locs=true, simple=true)

        elseif command == "help" || command == "h" || command == "?"
            println("\nCommands:")
            println("  Enter       - Play next move")
            println("  0-9         - Reset to starting position N")
            println("  f           - Play out 4 plies")
            println("  ff          - Play out 8 plies")
            println("  b           - undo")
            println("  show        - Display current board")
            println("  help        - Show this help message")
            println("  q/quit/exit - Exit match player")

        elseif command == "q" || command == "quit" || command == "exit"
            println("Exiting match player")
            break
            println("  q/quit/exit - Exit match player")
        elseif command == "b" || command == "back" || command == "undo"
            undo_action!(board)
            println("\nUndid last move")
            show(board; show_locs=true, simple=true)

        else
            println("Unknown command: '$command' (type 'help' for commands)")
        end

        println("ok")
    end

    return nothing
end
