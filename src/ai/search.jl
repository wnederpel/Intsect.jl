
function get_best_move(
    board::Board; depth=5000, time_limit_s=10.0, debug=true, method=:iterative_deepening
)::Action
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
    if method == :iterative_deepening
        best_move, best_score, full_path = iterative_deepening(
            board, board.current_color, board.ply, timed_out, depth, nodes_processed, debug;
        )
    elseif method == :minimax
        best_move, best_score, full_path = minimax(
            board, board.current_color, board.ply, timed_out, depth, nodes_processed, debug;
        )
    end

    close(timer)

    if debug
        println("done")
        println("Nodes processed: $(nodes_processed[])")
    end

    return ALL_ACTIONS[best_move]
end

function iterative_deepening(
    board::Board,
    my_color,
    initial_ply::Int,
    timed_out::Ref{Bool},
    max_depth,
    nodes_processed::Ref{Int},
    debug::Bool,
)
    full_path = Int[]
    best_move, best_score = -1, -1
    for depth in 1:max_depth
        best_move, best_score, full_path = minimax(
            board,
            board.current_color,
            initial_ply,
            timed_out,
            depth,
            nodes_processed,
            debug;
            suggested_path=full_path,
        )
        if timed_out[]
            break
        end
    end
    return best_move, best_score, full_path
end

function minimax(
    board::Board,
    my_color,
    initial_ply::Int,
    timed_out::Ref{Bool},
    depth,
    nodes_processed::Ref{Int},
    debug::Bool;
    suggested_path::Vector{Int}=Int[],
    alpha_one_up::Float64=-Inf64,
    beta_one_up::Float64=Inf64,
)
    maximizing = board.current_color == my_color ? true : false
    score_at_depth = maximizing ? -Inf : Inf
    action_chosen_at_depth = pass_index()
    path = Int[]

    steps_below_initial_ply = board.ply - initial_ply
    suggested_move =
        length(suggested_path) >= steps_below_initial_ply + 1 ?
        suggested_path[steps_below_initial_ply + 1] : -1

    final_lvl = depth == 1

    if board.gameover
        score = evaluate_board(board, my_color)
        return (pass_index(), score, Int[])
    end

    # Yield to allow timer to trigger
    yield()
    buffer = depth <= length(PERFT_BUFFER) ? PERFT_BUFFER[depth] : default_buffer(AllocBuffer)
    @no_escape buffer begin
        move_buffer = @alloc(eltype(Int), VALID_BUFFER_SIZE)
        validactions!(board, move_buffer)
        # TODO: this is probably a dumb way to do move ordering
        # Build move order: try suggested_move first if valid, then all others except suggested_move
        move_order = Int[]
        if suggested_move != -1
            for action_i in 1:(board.action_index - 1)
                action_as_index = move_buffer[action_i]
                if action_as_index == suggested_move
                    push!(move_order, action_as_index)
                    break
                end
            end
        end
        for action_i in 1:(board.action_index - 1)
            action_as_index = move_buffer[action_i]
            if action_as_index != suggested_move
                push!(move_order, action_as_index)
            end
        end

        for action_as_index in move_order
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
                _, score, sub_path = minimax(
                    board,
                    my_color,
                    initial_ply,
                    timed_out,
                    depth - 1,
                    nodes_processed,
                    debug;
                    alpha_one_up=alpha,
                    beta_one_up=beta,
                    suggested_path=suggested_path,
                )
            end
            undo(board)

            if (score > score_at_depth && maximizing) || (score < score_at_depth && !maximizing)
                score_at_depth = score
                action_chosen_at_depth = action_as_index
                path = sub_path

                if debug
                    # Printing things
                    if board.ply == initial_ply
                        show(ALL_ACTIONS[action_chosen_at_depth], board)
                        # Show the full path being considered
                        full_path = vcat(action_as_index, path)
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
            if timed_out[]
                # If we are timed out we stop after one iteration 
                break
            end
        end
    end

    return (action_chosen_at_depth, score_at_depth, vcat(action_chosen_at_depth, path))
end