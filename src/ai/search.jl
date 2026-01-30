
function get_best_move(board::Board; depth=3, time_limit_s=10.0, debug=true)::Action
    timed_out = Ref(false)
    if time_limit_s <= 0
        time_limit_s = 9999
    end
    timer = Timer(time_limit_s) do _
        debug && println("stopping search bc of time")
        timed_out[] = true
    end

    nodes_processed = Ref(0)
    alpha = Ref(-Inf)
    beta = Ref(Inf)
    best_move, best_score, full_path = search(
        board, board.current_color, timed_out, depth, depth, nodes_processed, debug;
    )

    close(timer)

    if debug
        println("done")
        println("Nodes processed: $(nodes_processed[])")
    end

    return ALL_ACTIONS[best_move]
end

function search(
    board::Board,
    my_color,
    timed_out::Ref{Bool},
    max_depth,
    depth,
    nodes_processed::Ref{Int},
    debug::Bool;
    alpha_one_up::Float64=-Inf64,
    beta_one_up::Float64=Inf64,
)
    maximizing = board.current_color == my_color ? true : false
    score_at_depth = maximizing ? -Inf : Inf
    action_chosen_at_depth = pass_index()
    best_path = Int[]

    final_lvl = depth == 1

    yield()
    if timed_out[]
        return action_chosen_at_depth, score_at_depth, Int[]
    end

    @no_escape PERFT_BUFFER[depth] begin
        move_buffer = @alloc(eltype(Int), VALID_BUFFER_SIZE)
        validactions!(board, move_buffer)
        for action_i in 1:(board.action_index - 1)
            action_as_index = move_buffer[action_i]

            do_action(board, action_as_index)

            nodes_processed[] += 1
            if final_lvl
                score = evaluate_board(board, my_color)
                sub_path = Int[]
            else
                if maximizing
                    alpha = score_at_depth
                    beta = beta_one_up
                else
                    alpha = alpha_one_up
                    beta = score_at_depth
                end
                _, score, sub_path = search(
                    board,
                    my_color,
                    timed_out,
                    max_depth,
                    depth - 1,
                    nodes_processed,
                    debug;
                    alpha_one_up=alpha,
                    beta_one_up=beta,
                )
            end
            undo(board)

            if (score > score_at_depth && maximizing) || (score < score_at_depth && !maximizing)
                score_at_depth = score
                action_chosen_at_depth = action_as_index
                best_path = sub_path

                if debug
                    # Printing things
                    if depth == max_depth
                        show(ALL_ACTIONS[action_chosen_at_depth], board)
                        # Show the full path being considered
                        full_path = vcat(action_as_index, best_path)
                        debug && println("Best path so far (score: $score_at_depth):")
                        for (i, action_idx) in enumerate(full_path)
                            print("  Move $i: ")
                            show(ALL_ACTIONS[action_idx], board)
                            do_action(board, action_idx)
                        end
                        # Undo all the moves we made for display
                        for _ in 1:length(full_path)
                            undo(board)
                        end
                        debug && println()
                    end
                end

                if maximizing && beta_one_up <= score_at_depth
                    break
                elseif !maximizing && score_at_depth <= alpha_one_up
                    break
                end
            end
        end
    end

    return (action_chosen_at_depth, score_at_depth, vcat(action_chosen_at_depth, best_path))
end