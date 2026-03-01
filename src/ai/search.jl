
function get_best_move(board::Board; depth=5000, time_limit_s=10.0, debug=true)::Action
    timed_out = Ref(false)
    if time_limit_s <= 0
        time_limit_s = 9999
    end
    debug && show(GameString(board))
    timer = Timer(time_limit_s) do _
        debug && println("stopping search bc of time")
        timed_out[] = true
    end

    nodes_processed = Ref(0)
    alpha = Ref(-Inf32)
    beta = Ref(Inf32)

    best_move, best_score = iterative_deepening(
        board, board.ply, timed_out, depth, nodes_processed, debug;
    )

    close(timer)

    if debug
        println("done")
        println("Nodes processed: $(format_with_dots(nodes_processed[]))")
        println("Best score: $best_score")
        show(ALL_ACTIONS[best_move], board)
    end

    return ALL_ACTIONS[best_move]
end

function iterative_deepening(
    board::Board,
    initial_ply::UInt16,
    timed_out::Ref{Bool},
    iterative_deepening_depth::Int,
    nodes_processed::Ref{Int},
    debug::Bool,
)
    # For testing, always test the move "wA3 \bM" at the root
    best_move, second_best, best_score = Int32(-1), Int32(-1), -Inf32

    # Clear the pv store
    for i in 1:PV_STORE_SIZE
        all(board.pv_store[i] .== -1) && break
        board.pv_store[i] .= -1
    end

    @no_escape begin
        for depth in 1:iterative_deepening_depth
            debug && println("iterative deepening at depth $depth")
            debug && println("best, second best = $best_move, $second_best")
            depth = Float32(depth)
            extension_budget = depth * 0.5f0

            buffer_idx = 1
            buff = @alloc(eltype(Int32), VALID_BUFFER_SIZE)
            sa = SuggestedActions(buff, board)
            add!(sa, second_best)

            best_score, _ = minimax(
                board,
                initial_ply,
                timed_out,
                depth,
                depth,
                extension_budget,
                buffer_idx,
                nodes_processed,
                debug,
                board.pv_store[1][1];
                suggested_moves=sa,
                is_pv_node=true,
            )
            new_best_move = board.pv_store[1][1]
            if new_best_move != best_move
                # The idea behind this to test a move that was previously thought to be good at the root lvl, not at the iterative deepening lvl
                second_best = best_move
                best_move = new_best_move
            end

            if timed_out[] || best_score == Inf32 || best_score == -Inf32
                break
            end
        end
    end
    if best_move == Int32(-1)
        best_move = action_index(rand(validactions(board), 1)[begin])
        debug && println("No valid moves found, returning a random move")
        debug && show(best_move, board)
        # No valid moves, just return a pass
    end

    return best_move, best_score
end

function minimax(
    board::Board,
    initial_ply::UInt16,
    timed_out::Ref{Bool},
    depth::Float32,
    initial_depth::Float32,
    extension_budget::Float32,
    buffer_idx::Int,
    nodes_processed::Ref{Int},
    debug::Bool,
    pv_move::Int32;
    suggested_moves::SuggestedActions,
    is_pv_node::Bool=false,
    alpha::Float32=-Inf32,
    beta::Float32=Inf32,
)
    final_lvl = depth < 1.5
    if board.gameover || depth < 0.5
        score = evaluate_board(board; debug=false)
        return score, Int32(-1)
    end
    current_hash = get_hash_value(board)
    search_entry = board.search_store[(current_hash & SEARCH_STORE_MASK) + 1]

    stored_suggested_move = Int32(-1)
    stored_refutation_move = Int32(-1)
    if search_entry.full_hash == current_hash
        stored_score = search_entry.score
        stored_suggested_move = search_entry.action_chosen
        stored_refutation_move = search_entry.refutation_move
        if search_entry.depth > depth - 0.05f0
            # if search_entry.type == :exact && !is_pv_node
            #     return stored_score, stored_refutation_move
            # elseif search_entry.type == :lowerbound && stored_score >= beta
            #     return stored_score, stored_refutation_move
            # elseif search_entry.type == :upperbound && stored_score <= alpha
            #     return stored_score, stored_refutation_move
            # end
        end
    end

    # maximizing = board.current_color == WHITE
    score_at_depth = -Inf32
    action_chosen_at_depth = pass_index()

    steps_below_initial_ply = board.ply - initial_ply

    type = :exact
    if steps_below_initial_ply <= initial_depth - 3
        # Yield to allow timer to trigger
        yield()
    end

    @assert steps_below_initial_ply + 1 == buffer_idx

    killer_move_by_me = Int32(-1)
    buffer = depth <= length(PERFT_BUFFER) ? PERFT_BUFFER[buffer_idx] : default_buffer(AllocBuffer)

    @no_escape buffer begin
        move_buffer = @alloc(eltype(Int32), VALID_BUFFER_SIZE)
        ordered_move_buffer = @alloc(eltype(Int32), VALID_BUFFER_SIZE)
        validactions!(board, move_buffer)

        good_moves_buffer = @alloc(eltype(Int32), VALID_BUFFER_SIZE)
        normal_moves_buffer = @alloc(eltype(Int32), VALID_BUFFER_SIZE)
        bad_moves_buffer = @alloc(eltype(Int32), VALID_BUFFER_SIZE)
        suggested_moves_buffer = @alloc(eltype(Int32), VALID_BUFFER_SIZE)

        if !final_lvl
            # Think about sharing killer moves between searches / different ply of the search.
            # Then we can just pass a white and black suggested actions around and make it like circular with like max 20 entries. 
            buff = @alloc(eltype(Int32), VALID_BUFFER_SIZE)
            killer_moves_by_opp = SuggestedActions(buff, board)
        else
            killer_moves_by_opp = DUMMY_SUGGESTED_ACTIONS
        end

        idx = order_moves!(
            ordered_move_buffer,
            board,
            move_buffer,
            pv_move,
            suggested_moves,
            good_moves_buffer,
            normal_moves_buffer,
            bad_moves_buffer,
            suggested_moves_buffer,
        )

        # for i in 1:idx
        #     action_as_index = ordered_move_buffer[i]
        for i in 1:(board.action_index - 1)
            action_as_index = move_buffer[i]

            do_action(board, action_as_index)

            nodes_processed[] += 1

            new_depth = depth - 1.0f0
            # Here we can do search extensions, but the evaluation seems to jump between even and odd ply This needs to be compensated somehow
            # Maybe this is a general problem with the evaluation at the moment..
            returned_score, killer_move_by_opp = minimax(
                board,
                initial_ply,
                timed_out,
                new_depth,
                initial_depth,
                extension_budget,
                buffer_idx + 1,
                nodes_processed,
                debug,
                board.pv_store[1][steps_below_initial_ply + 2];
                alpha=-beta,
                beta=-alpha,
                suggested_moves=killer_moves_by_opp, # These are good moves the opp might be able to make
                is_pv_node=(is_pv_node && action_as_index == pv_move),
            )
            score = -returned_score
            if killer_move_by_opp != Int32(-1)
                if !(contains(killer_move_by_opp, killer_moves_by_opp))
                    add!(killer_moves_by_opp, killer_move_by_opp)
                end
            end
            undo(board)

            if score > score_at_depth || score_at_depth == -Inf32
                score_at_depth = score
                action_chosen_at_depth = action_as_index
            end

            if beta <= score_at_depth
                # beta cut off 
                type = :lowerbound
                killer_move_by_me = action_as_index
                break
            end

            if score_at_depth > alpha
                # This is a pv move
                alpha = score_at_depth

                board.pv_store[steps_below_initial_ply + 1][steps_below_initial_ply + 1] =
                    action_as_index
                if final_lvl
                    # Terminate PV — no children to copy from
                    if steps_below_initial_ply + 2 <= PV_STORE_SIZE
                        board.pv_store[steps_below_initial_ply + 1][steps_below_initial_ply + 2] = Int32(
                            -1
                        )
                    end
                else
                    board.pv_store[steps_below_initial_ply + 1][(steps_below_initial_ply + 2):end] = board.pv_store[steps_below_initial_ply + 2][(steps_below_initial_ply + 2):end]
                end
                if debug
                    search_debug_print(board, initial_ply, score_at_depth, action_chosen_at_depth)
                end
            end

            if timed_out[]
                # If we are timed out we stop after one iteration 
                type = :incomplete
                break
            end
        end
    end

    if (
        is_pv_node ||
        current_hash != search_entry.full_hash ||
        type == :exact ||
        search_entry.depth < depth + 0.05
    )
        # Much to improve with transpositions tables.
        # https://deepwiki.com/search/does-stock-fish-have-a-tt-and_9a5e715f-a810-42f7-8ffb-901171686393
        # https://www.chessprogramming.org/Triangular_PV-table
        entry = SearchStoreEntry(
            current_hash, score_at_depth, depth, action_chosen_at_depth, type, killer_move_by_me
        )
        board.search_store[(current_hash & SEARCH_STORE_MASK) + 1] = entry
    end

    return score_at_depth, killer_move_by_me
end

function search_debug_print(board, initial_ply, score_at_depth, action_chosen_at_depth)
    # Printing things
    if board.ply == initial_ply
        show(ALL_ACTIONS[action_chosen_at_depth], board)
        println("Best path so far (score: $score_at_depth):")
        # Print the principal variation from pv_store
        done_actions = 0
        for action_idx in board.pv_store[begin]
            if action_idx == -1
                break
            end
            done_actions += 1
            print("  PV Move $(done_actions): ")
            show(ALL_ACTIONS[action_idx], board)

            do_action(board, action_idx)
        end
        for _ in 1:done_actions
            undo(board)
        end
        println()
    end
end

function count_queen_spots(board)
    if board.queen_pos_white < 0 || board.queen_pos_black < 0
        return -1, -1
    end
    open_white = 0
    for n in allneighs(board.queen_pos_white)
        if get_tile_on_board(board, n) == EMPTY_TILE
            open_white += 1
        end
    end
    open_black = 0
    for n in allneighs(board.queen_pos_black)
        if get_tile_on_board(board, n) == EMPTY_TILE
            open_black += 1
        end
    end
    return open_white, open_black
end

function order_moves!(
    ordered_move_buffer,
    board,
    move_buffer,
    last_best::Int32,
    suggested_moves::SuggestedActions,
    good_moves_buffer,
    normal_moves_buffer,
    bad_moves_buffer,
    suggested_moves_buffer,
)
    # Always try the last best move first if it's possible 
    # Validate that suggested moves are actually valid for the current position.
    valid_best_move = Int32(-1)

    suggested_moves_index = 0
    good_moves_index = 0
    normal_moves_index = 0
    bad_moves_index = 0

    for move in 1:(board.action_index - 1)
        action_as_index = move_buffer[move]
        if action_as_index == last_best
            valid_best_move = action_as_index

        elseif contains(action_as_index, suggested_moves)
            suggested_moves_buffer[suggested_moves_index += 1] = action_as_index

        elseif action_type(action_as_index) == Move
            move = ALL_MOVEMENTS[action_as_index - MAX_PLACEMENT_INDEX]
            tile = get_tile_on_board(board, move.moving_loc)
            bug = UInt8(get_tile_bug(tile))
            if (bug == UInt8(Bug.ANT) || bug == UInt8(Bug.MOSQUITO))
                good_moves_buffer[good_moves_index += 1] = action_as_index
            elseif (bug == UInt8(Bug.GRASSHOPPER) || bug == UInt8(Bug.SPIDER))
                bad_moves_buffer[bad_moves_index += 1] = action_as_index
            else
                normal_moves_buffer[normal_moves_index += 1] = action_as_index
            end
        elseif action_type(action_as_index) == Placement
            placement = ALL_PLACEMENTS[action_as_index]
            bug = get_tile_bug(placement.tile)
            if bug == UInt8(Bug.ANT) || bug == UInt8(Bug.MOSQUITO)
                normal_moves_buffer[normal_moves_index += 1] = action_as_index
            else
                bad_moves_buffer[bad_moves_index += 1] = action_as_index
            end
        else
            normal_moves_buffer[normal_moves_index += 1] = action_as_index
        end
    end
    idx = 0
    if valid_best_move != Int32(-1)
        ordered_move_buffer[idx += 1] = valid_best_move
    end
    for move_i in 1:suggested_moves_index
        ordered_move_buffer[idx += 1] = suggested_moves_buffer[move_i]
    end
    for move_i in 1:good_moves_index
        ordered_move_buffer[idx += 1] = good_moves_buffer[move_i]
    end
    for move_i in 1:normal_moves_index
        ordered_move_buffer[idx += 1] = normal_moves_buffer[move_i]
    end
    for move_i in 1:bad_moves_index
        ordered_move_buffer[idx += 1] = bad_moves_buffer[move_i]
    end

    return idx
end