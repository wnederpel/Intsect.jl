@testitem "Placement location generation" begin
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

@testitem "Placement location generation after undo" begin
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

@testitem "Placement location generation after undo 2" begin

    # do a bunch of moves
    game = raw"wA1;bA1 \wA1;wA2 wA1-;bA2 bA1/;wP wA2/"
    movestrings = split(game, ';')

    board = handle_newgame_command(Gametype.MLP)

    for movestring in movestrings
        action = action_from_move_string(board, movestring)
        do_action(board, action)
    end

    # Undo a placement that had neighs where black should be able to place after undoing
    undo(board)

    # then do some other placement
    action = action_from_move_string(board, "wA3 wA2-")
    do_action(board, action)

    # Test that it all works out
    @test length(board.placement_locs[board.current_color + 1]) == 5
    @test board.placement_locs[board.current_color + 1] == BitSet([86, 87, 102, 104, 118])

    # This somehow changed the outcome in the tests
    GameString(board)

    @test length(board.placement_locs[board.current_color + 1]) == 5
    @test board.placement_locs[board.current_color + 1] == BitSet([86, 87, 102, 104, 118])
end
