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
    # is pinned will be used throughout the evaluation
    update_ispinned_general!(board)

    # This is redundant
    # update_ispinned_general!(board)
    # # Give score for having non-pinned pieces
    # my_tile_score, my_pinning_score = freedom_score(board, WHITE)
    # score += my_tile_score + my_pinning_score
    # debug && println("White tile score: $my_tile_score, White pinning score: $my_pinning_score")
    # opp_tile_score, opp_pinning_score = freedom_score(board, BLACK)
    # score -= opp_tile_score + opp_pinning_score
    # debug && println("Black tile score: $opp_tile_score, Black pinning score: $opp_pinning_score")

    # This is too slow
    # score += placement_score(board, WHITE)
    # debug && println("White placement score: $(placement_score(board, WHITE))")
    # score -= placement_score(board, BLACK)
    # debug && println("Black placement score: $(placement_score(board, BLACK))")

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

    # Piece freedom: reward having unpinned, mobile pieces
    white_freedom = piece_freedom_score(board, WHITE) * 0.5
    score += white_freedom
    debug && println("White piece freedom score: $white_freedom")
    black_freedom = piece_freedom_score(board, BLACK) * 0.5
    score -= black_freedom
    debug && println("Black piece freedom score: $black_freedom")

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

function placement_score(board, color)
    score_ref = Ref(0.0f0)
    for_placement_locs(board, color) do loc
        # It's good to have more placement options
        score_ref[] += 0.05f0
        return nothing
    end
    return score_ref[]
end

# function freedom_score(board, color)
#     tile_score_ref = Ref(0.0f0)
#     pinning_score = 0.0f0
#     for_each_tile(board, color) do tile, loc
#         if loc < 0
#             if loc == UNDERGROUND
#                 # The piece is underground, it happens
#                 return nothing
#             end
#             error("for each tile returned tile $tile at loc $loc, which is invalid")
#         end
#         tile_score_ref[] += get_tile_score(board, tile, loc)

#         return nothing
#     end

#     return tile_score_ref[], pinning_score
# end

# function get_pinning_score(board, tile, loc)
#     has_one, neigh_loc = has_one_neigh_and_get(board, loc)
#     if has_one
#         neigh_tile = get_tile_on_board(board, neigh_loc)
#         if get_tile_color(neigh_tile) != get_tile_color(tile)
#             # tile is pinning an enemy piece, that's good
#             pinning_bug = get_tile_bug(tile)
#             pinned_bug = get_tile_bug(neigh_tile)
#             pinned_bug_score = get_bug_score(pinned_bug)
#             pinning_bug_score = get_bug_score(pinning_bug)
#             if pinning_bug == Integer(Bug.MOSQUITO) && pinned_bug == Integer(Bug.MOSQUITO)
#                 # This is quite bad, the mosquito is stuck, we need to compensate for the tile score that we gave
#                 return -pinning_bug_score * 2.0f0
#             end
#             return pinned_bug_score + -pinning_bug_score * 0.25f0
#         end
#     end
#     return 0.0f0
# end

# function get_tile_score(board, tile, loc)
#     height = get_tile_height(tile)
#     if height > 1
#         # Pieces on top are computed separately
#         return 0.0f0
#     end
#     # The bug score is positive if it's not pinned, otherwise it's negative
#     bug = get_tile_bug(tile)
#     bug_score = get_bug_score(bug)
#     if board.ispinned[loc]
#         if bug == Integer(Bug.BEETLE)
#             # It's very bad if the beetle is pinned
#             return -bug_score * 2.0f0
#         end
#         # It's not that bad when the piece is pinned, it can be freed and it keeps a black piece occupied
#         return -bug_score * 0.5f0
#     else
#         # It's nice if it's free
#         return bug_score
#     end
# end

# @inline function get_max_bug_score()
#     return 8.0f0
# end

# @inline function get_bug_score(bug)
#     if bug == Integer(Bug.ANT)
#         return 8.0f0
#     elseif bug == Integer(Bug.GRASSHOPPER)
#         return 2.0f0
#     elseif bug == Integer(Bug.BEETLE)
#         return 6.0f0
#     elseif bug == Integer(Bug.SPIDER)
#         return 2.0f0
#     elseif bug == Integer(Bug.QUEEN)
#         return 1.0f0
#     elseif bug == Integer(Bug.LADYBUG)
#         return 5.0f0
#     elseif bug == Integer(Bug.PILLBUG)
#         return 1.0f0
#     elseif bug == Integer(Bug.MOSQUITO)
#         return 6.0f0
#     else
#         return 0.0f0
#     end
# end

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

function piece_freedom_score(board::Board, color)
    # Assumes update_ispinned_general! has already been called
    score = 0.0f0
    my_queen_loc = color == WHITE ? board.queen_pos_white : board.queen_pos_black

    for bug in 0x01:0x08
        if get_tile_bug_num(board.placeable_tiles[color][bug]) == 0
            # This just means that the tile is not yet placed apparently
            continue
        end
        for num in 0x00:MAX_NUMS[bug]
            semi_tile = tile_from_info_as_index(color, bug, num)
            @inbounds loc = board.tile_locs[semi_tile + 1]

            if loc == NOT_PLACED
                break
            end
            if loc == UNDERGROUND || loc == INVALID_LOC
                continue
            end
            tile = get_tile_on_board(board, loc)
            if loc < 0
                continue
            end
            height = get_tile_height(tile)
            bug = get_tile_bug(tile)

            if height > 1
                # Piece is on top of the hive — it's counted by the top of hive score
                continue
            end

            if board.ispinned[loc]
                # Pinned (articulation point) — can't move
                if bug == Integer(Bug.BEETLE)
                    # Beetle pinned on the ground is very bad — it's your best piece stuck
                    score -= 3.0f0
                end
                continue
            end

            # Piece is free — give score based on bug type
            bug_value = freedom_bug_score(board, bug, loc)

            neigh_loc = EMPTY_TILE
            neighs = 0
            for n in allneighs(loc)
                if get_tile_on_board(board, n) != EMPTY_TILE
                    neigh_loc = n
                    neighs += 1
                    if bug != Integer(Bug.ANT) && bug != Integer(Bug.SPIDER)
                        break
                    end
                end
            end
            # Discount the value if the piece is adjacent to a single enemy high lvl piece
            if neighs == 1
                neigh_tile = get_tile_on_board(board, neigh_loc)
                # This is not idea regardless of the color, either you are pinning a good pice of yourself which is bad, or you are next to a strong enemy piece which you have to keep pinned
                neigh_bug = get_tile_bug(neigh_tile)
                neigh_bug_value = freedom_bug_score(neigh_bug)
                heigh_bug_height = get_tile_height(neigh_tile)
                if heigh_bug_height == 1
                    # It's not that bad, the piece can still move, but it's less good
                    # this value is 0.5 if the neigh is strong, 1 if it's weak
                    discount_rate = (1 - neigh_bug_value / max_bug_score()) * 0.5f0 + 0.5f0
                    bug_value *= discount_rate
                end
            elseif neighs >= 5
                # The piece is stuck if it's an ant or spider
                if bug == Integer(Bug.ANT) || bug == Integer(Bug.SPIDER)
                    continue
                end
            end
            score += bug_value
        end
    end
    return score
end

@inline function max_bug_score()
    return 13.0f0
end

function freedom_bug_score(board, bug, loc)
    if bug == Integer(Bug.MOSQUITO)
        # The mosquito's freedom is a bit special, it depends on what it's mimicking
        # We take the best case (the one that gives the highest freedom score) among the possible mimics
        best_score = 0.0f0
        for n in allneighs(loc)
            neigh_tile = get_tile_on_board(board, n)
            if neigh_tile == EMPTY_TILE
                continue
            end
            neigh_bug = get_tile_bug(neigh_tile)
            score = freedom_bug_score(neigh_bug) - 0.5f0  # The mosquito is a bit less free than the bug it's mimicking, to account for the fact that it can't always mimic perfectly
            if score > best_score
                best_score = score
                if best_score > max_bug_score() - 0.1f0
                    return best_score
                end
            end
        end
        return best_score
    end
    return freedom_bug_score(bug)
end

@inline function freedom_bug_score(bug)
    if bug == Integer(Bug.ANT)
        return 13.0f0
    elseif bug == Integer(Bug.BEETLE)
        return 12.0f0
    elseif bug == Integer(Bug.MOSQUITO)
        return 0.0f0
    elseif bug == Integer(Bug.LADYBUG)
        return 6.0f0
    elseif bug == Integer(Bug.PILLBUG)
        return 1.5f0
    elseif bug == Integer(Bug.SPIDER)
        return 0.5f0
    elseif bug == Integer(Bug.GRASSHOPPER)
        return 0.5f0
    elseif bug == Integer(Bug.QUEEN)
        return 2.5f0
    else
        return 0.0f0
    end
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
    for loc in allneighs(queen_loc)
        tile = get_tile_on_board(board, loc)
        # An empty tile is good
        if tile == EMPTY_TILE
            total_free += 1
            score += 2.0f0
        else
            # A tile of my color is not bad not good
            if get_tile_color(tile) == color
                # My pillbug is essential to have around, it can move the queen if needed
                pill_bug_bonus = 20.0f0
                if get_tile_bug(tile) == Integer(Bug.PILLBUG)
                    score += pill_bug_bonus
                    pill_bug_bonus = 0.0f0  # Only count the pillbug once, even if there are multiple adjacent
                elseif get_tile_bug(tile) == Integer(Bug.MOSQUITO)
                    for mos_neigh in allneighs(loc)
                        mos_neigh_tile = get_tile_on_board(board, mos_neigh)
                        if get_tile_bug(mos_neigh_tile) == Integer(Bug.PILLBUG)
                            # A mosquito mimicking a pillbug is as good as a real pillbug
                            score += pill_bug_bonus
                            break
                        end
                    end
                    pill_bug_bonus = 0.0f0  # Only count the pillbug once, even if there are multiple adjacent
                else
                    # It's bad if a pinned friendly piece is next to my queen (although we don't care about the pillbug, it can still move the queen)
                    if board.ispinned[loc]
                        score -= 5.0f0
                    end
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
        # Some other tile (a climber) in on top of the queen, that's bad if the queen is close to being
        score -= 5 * total_free
    else
        if board.ispinned[queen_loc]
            # The queen is pinned, that's not nice 
            score -= 3.0f0
        end
    end
    # if total_free == 1
    #     # Close to death
    #     score -= 20.0f0
    # end
    return score
end
