
function get_best_move(board::Board, depth, time_limit_s)
    timed_out = Ref(false)
    timer = Timer(time_limit_s) do _
        timed_out[] = true
    end

    best_move, best_score = bf_search(board, board.current_color, timed_out, depth, depth)

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
    if depth == 0
        score = evaluate_board(board, my_color)
        return action_chosen_at_depth, score
    end
    yield()
    if timed_out[]
        return best_yet, best_score
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
            _, score = bf_search(
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
                if depth == max_depth
                    show(ALL_ACTIONS[action_chosen_at_depth], board)
                end
            end
        end
    end


    return action_chosen_at_depth, score_at_depth
end