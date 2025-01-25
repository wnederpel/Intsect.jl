@testitem "Placement location generation after undo ply 2" begin
    board = handle_newgame_command(Gametype.MLP)

    do_action(board, action_from_move_string(board, "wP"))
    do_action(board, action_from_move_string(board, "bP wP-"))
    undo(board)
    do_action(board, action_from_move_string(board, "bP wP\\"))
    undo(board)
    do_action(board, action_from_move_string(board, "bP wP/"))

    actions = validactions(board)

    @assert length(actions) == 7 * 3
end
