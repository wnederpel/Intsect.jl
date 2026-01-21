
function evaluate_board(board::Board, evaluate_for_color)
    return evaluate_board(
        board,
        evaluate_for_color,
        evaluate_for_color == WHITE ? board.queen_pos_white : board.queen_pos_black,
        evaluate_for_color == WHITE ? board.queen_pos_black : board.queen_pos_white,
    )
end

function evaluate_board(board::Board, my_color, my_queen, opponent_queen)
    #= 
    To be extended with other evaluations. Simple for now to just the search working.
    Pinned pieces (re compute what's pinned, it's good if pieces are not pinned, especially queen, ant, mosquito, ladybug, beetle (can be on top and unpinnable))
    Moves (having many moves is good, having a move towards the queen is good)
    =#
    score = 0

    # Evaluate queen safety, having my queen safe is good, having opponent queen safe is bad
    score += evaluate_queen_safety(board, my_color, my_queen)
    score -= evaluate_queen_safety(board, my_color == WHITE ? BLACK : WHITE, opponent_queen)

    # Having bugs on top of the hive is good if their mine, bad if opponent's
    my_pieces = board.pieces[my_color == WHITE ? 1 : 2]
    their_pieces = board.pieces[my_color == WHITE ? 2 : 1]
    score += top_of_hive_score(board, my_pieces)
    score -= top_of_hive_score(board, their_pieces)

    return score
end

function top_of_hive_score(board, pieces)
    score = 0
    for loc in board.tile_locs
        if loc < 0
            continue
        end
        tile = get_tile_on_board(board, loc)
        height = get_tile_height(tile)
        if height >= 2
            # Having a tile on top of the hive is good
            score += 5
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
    if get_tile_bug(queen_tile) != Bug.QUEEN
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
                score += 4
                # My pillbug is even better
                if get_tile_bug(tile) == Bug.PILLBUG
                    score += 6
                end
            else
                # An opponent's tile is bad
                score -= 6
                # An opponent's pillbug is worse
                if get_tile_bug(tile) == Bug.PILLBUG
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
