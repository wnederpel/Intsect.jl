function evaluate_board(board::Board; debug=false)::Float32
    if board.gameover
        # Game is over, return extreme score
        if board.victor == board.current_color
            return Inf32
        elseif board.victor == Intsect.DRAW
            return 0.0f0
        else
            return -Inf32
        end
    end
    #= 
    To be extended with other evaluations. Simple for now to just the search working.
    Pinned pieces: re-compute what's pinned, then give score if good pieces are not pinned

    IDEA: we should have an idea on what happens when either side races to the enemy queen.
    It's good if we can win that race (as good as the number of free spots remaining)
    It's bad if not (as bad as the number of free spots on their queen remaining) 
    =#

    score = 0.0f0

    queen_safety_factor = 1.0f0 + min(max(Float32(board.ply - 15) / 10.0f0, 0.0f0), 2.0f0)

    # Evaluate queen safety, having my queen safe is good, having opponent queen safe is bad
    white_queen_safety =
        evaluate_queen_safety(board, WHITE, board.queen_pos_white) * queen_safety_factor
    score += white_queen_safety
    debug && println("White queen safety score: $white_queen_safety")
    black_queen_safety =
        evaluate_queen_safety(board, BLACK, board.queen_pos_black) * queen_safety_factor
    score -= black_queen_safety
    debug && println("Black queen safety score: $black_queen_safety")

    # Having bugs on top of the hive is good if their mine, bad if opponent's
    top_hive = top_of_hive_score(board)
    debug && println("Top of hive score: $top_hive")
    score += top_hive

    # Penalize keeping key pieces in hand
    white_hand = pieces_in_hand_penalty(board, WHITE)
    score += white_hand
    debug && println("White pieces-in-hand penalty: $white_hand")
    black_hand = pieces_in_hand_penalty(board, BLACK)
    score -= black_hand
    debug && println("Black pieces-in-hand penalty: $black_hand")

    debug && println("Raw score before color adjustment: $score")
    if board.current_color == BLACK
        score *= -1
    end
    return score
end

function top_of_hive_score(board)
    score = 0.0f0

    for loc in board.tile_locs
        if loc < 0
            continue
        end
        tile = get_tile_on_board(board, loc)
        height = get_tile_height(tile)
        if height >= 2
            top_color = get_tile_color(tile)

            opponent_queen_loc = top_color == WHITE ? board.queen_pos_black : board.queen_pos_white
            my_queen_loc = top_color == WHITE ? board.queen_pos_white : board.queen_pos_black

            added_score = 2.0f0  # base value: having something on top of the hive

            # Beetle on top near the enemy queen is very threatening
            if opponent_queen_loc >= 0
                if are_neighs(loc, opponent_queen_loc)
                    added_score += 8.0f0
                end
            end

            # Beetle on top near my own queen helps defend
            if my_queen_loc >= 0
                if are_neighs(loc, my_queen_loc)
                    added_score += 2.0f0
                end
            end

            if top_color == WHITE
                score += added_score
            else
                score -= added_score
            end
        end
    end
    return score
end

function pieces_in_hand_penalty(board::Board, color)
    penalty = 0.0f0
    ply = board.ply

    # Ants (bug index 1): penalize from the start, ramp up over time
    # 3 ants total (MAX_NUMS[1] = 2, bug_nums 0,1,2)
    ant_tile = board.placeable_tiles[color][Integer(Bug.ANT)]
    if ant_tile != EMPTY_TILE
        in_hand = MAX_NUMS[Integer(Bug.ANT)] - get_tile_bug_num(ant_tile) + 1
        # Ramp: small early, grows with ply. At ply 8 penalty is ~0.8 per ant, at ply 20 ~2.0
        ramp = min(Float32(ply) / 10.0f0, 2.0f0)
        penalty -= Float32(in_hand) * ramp * 0.5f0
    end

    # Mosquito (bug index 8): penalize from the start
    mosquito_tile = board.placeable_tiles[color][Integer(Bug.MOSQUITO)]
    if mosquito_tile != EMPTY_TILE
        ramp = min(Float32(ply) / 8.0f0, 2.5f0)
        penalty -= ramp * 0.5f0
    end

    # Pillbug (bug index 7): penalize from the start
    pillbug_tile = board.placeable_tiles[color][Integer(Bug.PILLBUG)]
    if pillbug_tile != EMPTY_TILE
        ramp = min(Float32(ply) / 10.0f0, 2.0f0)
        penalty -= ramp * 0.4f0
    end

    # Beetles (bug index 3): penalize only after ply 16
    # 2 beetles total (MAX_NUMS[3] = 1, bug_nums 0,1)
    beetle_tile = board.placeable_tiles[color][Integer(Bug.BEETLE)]
    if beetle_tile != EMPTY_TILE
        in_hand = MAX_NUMS[Integer(Bug.BEETLE)] - get_tile_bug_num(beetle_tile) + 1
        ramp = max(min(Float32(ply - 16) / 10.0f0, 1.5f0), 0.0f0)
        penalty -= Float32(in_hand) * ramp * 0.4f0
    end

    return penalty
end

function evaluate_queen_safety(board::Board, color, queen_loc)
    if queen_loc < 0
        # Queen is not yet placed
        return 0.0f0
    end
    # show(board)

    queen_tile = get_tile_on_board(board, queen_loc)
    if queen_tile == EMPTY_TILE
        println(queen_tile)
        queen_tile = get_tile_on_board(board, queen_loc)
        println(queen_tile)
        show(board; simple=true)

        println(get_tile_on_board(board, board.queen_pos_white))
        println(get_tile_on_board(board, queen_loc))

        wtile = get_tile_from_string(board, "wQ")
        wloc = get_loc(board, wtile)
        println(wloc)
        println(queen_loc)
        println(wtile)
        error("queen loc is valid but the tile at that loc is empty")
        return 0.0f0
    end
    score = 0.0f0

    total_free = 0
    queen_neighs = allneighs(queen_loc)
    for i in 1:6
        loc = queen_neighs[i]
        tile = get_tile_on_board(board, loc)
        # An empty tile is good
        if tile == EMPTY_TILE
            total_free += 1
            score += 2.0f0
        else
            # A tile of my color is not bad not good
            if get_tile_color(tile) == color
                # My pillbug next to queen is great — it can move the queen if needed
                pill_bug_bonus = 20.0f0
                tile_bug = get_tile_bug(tile)
                if tile_bug == Integer(Bug.PILLBUG) || tile_bug == Integer(Bug.MOSQUITO)
                    score += pill_bug_bonus
                    pill_bug_bonus = 0.0f0
                end
            else
                # An opponent's tile is bad
                score -= 3.0f0
                # An opponents climber is even worse
                if get_tile_height(tile) >= 2
                    score -= 10.0f0
                end
            end
        end
    end

    if get_tile_bug(queen_tile) != Integer(Bug.QUEEN)
        # Some other tile (a climber) is on top of the queen
        score -= 5 * total_free
    end

    return score
end
