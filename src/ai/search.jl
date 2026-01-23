
function get_best_move(board::Board, depth, time_limit_s)
    timed_out = Ref(false)
    timer = Timer(time_limit_s) do _
        println("stopping search bc of time")
        timed_out[] = true
    end

    best_move, best_score, _ = bf_search(board, board.current_color, timed_out, depth, depth)

    close(timer)

    return ALL_ACTIONS[best_move]
end

function bf_search(
    board::Board,
    my_color,
    timed_out::Ref{Bool},
    max_depth,
    depth;
    best_yet=pass_index(),
    best_score=Inf,
)
    maximizing = board.current_color == my_color ? true : false
    score_at_depth = maximizing ? -Inf : Inf
    action_chosen_at_depth = pass_index()
    best_path = Int[]
    if depth == 0
        score = evaluate_board(board, my_color)
        return action_chosen_at_depth, score, Int[]
    end
    yield()
    if timed_out[]
        return best_yet, best_score, Int[]
    end

    @no_escape PERFT_BUFFER[depth] begin
        move_buffer = @alloc(eltype(Int), VALID_BUFFER_SIZE)
        validactions!(board, move_buffer)
        for action_i in 1:(board.action_index - 1)
            action_as_index = move_buffer[action_i]
            if depth == max_depth
                best_yet = action_chosen_at_depth
                best_score = score_at_depth
            end

            do_action(board, action_as_index)
            _, score, sub_path = bf_search(
                board,
                my_color,
                timed_out,
                max_depth,
                depth - 1;
                best_yet=best_yet,
                best_score=best_score,
            )
            undo(board)

            if (score > score_at_depth && maximizing) || (score < score_at_depth && !maximizing)
                score_at_depth = score
                action_chosen_at_depth = action_as_index
                best_path = sub_path
                if depth == max_depth
                    show(ALL_ACTIONS[action_chosen_at_depth], board)
                    # Show the full path being considered
                    full_path = vcat(action_as_index, best_path)
                    println("Best path so far (score: $score_at_depth):")
                    for (i, action_idx) in enumerate(full_path)
                        print("  Move $i: ")
                        show(ALL_ACTIONS[action_idx], board)
                        do_action(board, action_idx)
                    end
                    # Undo all the moves we made for display
                    for _ in 1:length(full_path)
                        undo(board)
                    end
                    println()
                end
            end
        end
    end


    return action_chosen_at_depth, score_at_depth, vcat(action_chosen_at_depth, best_path)
end