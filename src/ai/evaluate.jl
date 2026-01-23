function evaluate_board(board::Board, my_color::Integer)
    @no_escape PERFT_BUFFER[end] begin
        white_moves = @alloc(eltype(Int), VALID_BUFFER_SIZE)
        validactions!(board, white_moves, WHITE)
        white_move_idx = board.action_index

        black_moves = @alloc(eltype(Int), VALID_BUFFER_SIZE)
        validactions!(board, black_moves, BLACK)
        black_move_idx = board.action_index

        score = evaluate_board(
            board, my_color, white_moves, white_move_idx, black_moves, black_move_idx
        )
    end
    return score
end

function evaluate_board(
    board::Board,
    my_color::Integer,
    white_actions::AbstractArray,
    white_action_index::Int,
    black_actions::AbstractArray,
    black_action_index::Int,
)
    return evaluate_board(
        board,
        my_color,
        my_color == WHITE ? board.queen_pos_white : board.queen_pos_black,
        my_color == WHITE ? board.queen_pos_black : board.queen_pos_white,
        my_color == WHITE ? (white_actions, white_action_index) :
        (black_actions, black_action_index),
        my_color == WHITE ? (black_actions, black_action_index) :
        (white_actions, white_action_index),
    )
end

function evaluate_board(
    board::Board,
    my_color::Integer,
    my_queen::Integer,
    opponent_queen::Integer,
    my_actions_tup::Tuple{AbstractArray,Int},
    opp_actions_tup::Tuple{AbstractArray,Int},
)
    #= 
    To be extended with other evaluations. Simple for now to just the search working.
    Pinned pieces (re compute what's pinned, it's good if pieces are not pinned, especially queen, ant, mosquito, ladybug, beetle (can be on top and unpinnable))
    Moves (having many moves is good, having a move towards the queen is good)
    =#
    score = 0
    score += movement_score(board, my_actions_tup)
    score -= movement_score(board, opp_actions_tup)

    # Evaluate queen safety, having my queen safe is good, having opponent queen safe is bad
    score += evaluate_queen_safety(board, my_color, my_queen)
    score -= evaluate_queen_safety(board, my_color == WHITE ? BLACK : WHITE, opponent_queen)

    # Having bugs on top of the hive is good if their mine, bad if opponent's
    score += top_of_hive_score(board, my_color)

    return score
end

function movement_score(board, actions_tup)
    score = 0
    actions, action_idx = actions_tup
    for action_i in 1:(action_idx - 1)
        action_as_index = actions[action_i]
        if action_type(action_as_index) != Placement
            score += 1
        end
    end

    return score
end

function top_of_hive_score(board, my_color)
    score = 0
    opponent_color = my_color == WHITE ? BLACK : WHITE

    for loc in board.tile_locs
        if loc < 0
            continue
        end
        tile = get_tile_on_board(board, loc)
        height = get_tile_height(tile)
        if height >= 2
            # Get the color of the top tile
            top_color = get_tile_color(tile)

            piece_below = top(board.underworld[loc])
            below_color = get_tile_color(piece_below)

            # Having my tile on top of an opponent's tile is good
            if top_color == my_color && below_color == opponent_color
                score += 10
            end
            if top_color == opponent_color && below_color == my_color
                score -= 10
            end
        end
    end
    return score
end

function evaluate_queen_safety(board::Board, color, queen_loc)
    if queen_loc < 0
        # Queen is not yet placed
        return 0
    end
    queen_tile = get_tile_on_board(board, queen_loc)
    if queen_tile == EMPTY_TILE
        show(board)
        error("queen loc is valid but the tile at that loc is empty")
        return 0
    end
    score = 0
    if get_tile_bug(queen_tile) != Integer(Bug.QUEEN)
        # Some other tile (a climber) in on top of the queen, that's bad
        score -= 40
    end

    for loc in allneighs(queen_loc)
        tile = get_tile_on_board(board, loc)
        # An empty tile is good
        if tile == EMPTY_TILE
            score += 4
        else
            # A tile of my color is fine
            if get_tile_color(tile) == color
                score += 3
                # My pillbug is even better
                if get_tile_bug(tile) == Integer(Bug.PILLBUG)
                    score += 6
                end
            else
                # An opponent's tile is bad
                score -= 6
                # An opponent's pillbug is worse
                if get_tile_bug(tile) == Integer(Bug.PILLBUG)
                    score -= 10
                end
                # An opponents climber is even worse
                if get_tile_height(tile) >= 2
                    score -= 14
                end
            end
        end
    end
    return score
end
