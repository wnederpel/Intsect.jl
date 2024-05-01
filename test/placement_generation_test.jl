@testitem "Test placement location generation" begin
    wQ_loc = MID - 1
    bQ_loc = MID + 2

    board = handle_newgame_command(Gametype.MLP)

    do_action(board, action_from_move_string(board, "wL"))
    do_action(board, action_from_move_string(board, "bL wL-"))

    do_action(board, action_from_move_string(board, "wQ -wL"))
    do_action(board, action_from_move_string(board, "bQ bL-"))

    @test length(board.placement_locs[2]) == 5
    @test apply_direction(wQ_loc, Direction.NW) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.NE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.W) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SW) in board.placement_locs[2]
    @test length(board.placement_locs[1]) == 5
    @test apply_direction(bQ_loc, Direction.NW) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.NE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.E) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SW) in board.placement_locs[1]

    do_action(board, action_from_move_string(board, "wB1 -wQ"))
    do_action(board, action_from_move_string(board, "bB1 bQ-"))

    @test length(board.placement_locs[1]) == 7
    @test length(board.placement_locs[2]) == 7

    do_action(board, action_from_move_string(board, "wB1 -wL"))
    do_action(board, action_from_move_string(board, "bB1 bL-"))

    @test length(board.placement_locs[2]) == 5
    @test apply_direction(wQ_loc, Direction.NW) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.NE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.W) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SW) in board.placement_locs[2]
    @test length(board.placement_locs[1]) == 5
    @test apply_direction(bQ_loc, Direction.NW) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.NE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.E) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SW) in board.placement_locs[1]
end

@testitem "Test placement location generation after undo" begin
    wQ_loc = MID - 1
    bQ_loc = MID + 2

    board = handle_newgame_command(Gametype.MLP)

    do_action(board, action_from_move_string(board, "wL"))
    undo(board)
    do_action(board, action_from_move_string(board, "wL"))

    do_action(board, action_from_move_string(board, "bL wL-"))
    undo(board)
    do_action(board, action_from_move_string(board, "bL wL-"))

    do_action(board, action_from_move_string(board, "wQ -wL"))
    do_action(board, action_from_move_string(board, "bQ bL-"))
    undo(board)
    undo(board)
    do_action(board, action_from_move_string(board, "wQ -wL"))
    do_action(board, action_from_move_string(board, "bQ bL-"))

    @test length(board.placement_locs[2]) == 5
    @test apply_direction(wQ_loc, Direction.NW) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.NE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.W) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SW) in board.placement_locs[2]
    @test length(board.placement_locs[1]) == 5
    @test apply_direction(bQ_loc, Direction.NW) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.NE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.E) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SW) in board.placement_locs[1]

    do_action(board, action_from_move_string(board, "wB1 -wQ"))
    do_action(board, action_from_move_string(board, "bB1 bQ-"))

    @test length(board.placement_locs[1]) == 7
    @test length(board.placement_locs[2]) == 7

    do_action(board, action_from_move_string(board, "wB1 -wL"))
    do_action(board, action_from_move_string(board, "bB1 bL-"))

    undo(board)
    undo(board)

    @test length(board.placement_locs[1]) == 7
    @test length(board.placement_locs[2]) == 7

    do_action(board, action_from_move_string(board, "wB1 -wL"))
    do_action(board, action_from_move_string(board, "bB1 bL-"))

    @test length(board.placement_locs[2]) == 5
    @test apply_direction(wQ_loc, Direction.NW) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.NE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.W) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SE) in board.placement_locs[2]
    @test apply_direction(wQ_loc, Direction.SW) in board.placement_locs[2]
    @test length(board.placement_locs[1]) == 5
    @test apply_direction(bQ_loc, Direction.NW) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.NE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.E) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SE) in board.placement_locs[1]
    @test apply_direction(bQ_loc, Direction.SW) in board.placement_locs[1]
end
