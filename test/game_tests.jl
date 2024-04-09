
# TODO test: add 'game' tests
# doing move updates underworld

@testitem "Doing a move updates ply, current color, turn, queens placed and just moved loc" begin
    using StaticArrays

    function test_board_state(
        board, ply, current_color, turn, queen_placed, just_moved_loc, moved_by_pillbug_loc
    )
        @test board.ply == ply
        @test board.current_color == current_color
        @test board.turn == turn
        @test board.queen_placed == queen_placed
        @test board.just_moved_loc == just_moved_loc
        @test board.moved_by_pillbug_loc == moved_by_pillbug_loc
    end

    # Define all pieces
    wS1 = get_tile_from_string("wS1")
    bS1 = get_tile_from_string("bS1")
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")
    wA1 = get_tile_from_string("wA1")
    bA1 = get_tile_from_string("bA1")

    wS2 = get_tile_from_string("wS2")

    # Define their locs
    wS1_loc = MID
    bS1_loc = apply_direction(wS1_loc, Direction.E)

    wQ_loc = apply_direction(wS1_loc, Direction.W)
    bQ_loc = apply_direction(bS1_loc, Direction.E)

    wA1_loc = apply_direction(wQ_loc, Direction.W)
    bA1_loc = apply_direction(bQ_loc, Direction.E)

    wS2_loc = apply_direction(wQ_loc, Direction.W)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    # Do the actions and check the board state 
    action1 = Placement(wS1_loc, wS1)
    @test action1 in validactions(board)
    do_action(board, action1)
    test_board_state(board, 2, BLACK, 1, MVector{2,Bool}(false, false), INVALID_LOC, INVALID_LOC)

    action2 = Placement(bS1_loc, bS1)
    @test action2 in validactions(board)
    do_action(board, action2)
    test_board_state(board, 3, WHITE, 2, MVector{2,Bool}(false, false), INVALID_LOC, INVALID_LOC)

    action3 = Placement(wQ_loc, wQ)
    @test action3 in validactions(board)
    do_action(board, action3)
    test_board_state(board, 4, BLACK, 2, MVector{2,Bool}(false, true), INVALID_LOC, INVALID_LOC)

    action4 = Placement(bQ_loc, bQ)
    @test action4 in validactions(board)
    do_action(board, action4)
    test_board_state(board, 5, WHITE, 3, MVector{2,Bool}(true, true), INVALID_LOC, INVALID_LOC)

    action5 = Placement(wA1_loc, wA1)
    @test action5 in validactions(board)
    do_action(board, action5)
    test_board_state(board, 6, BLACK, 3, MVector{2,Bool}(true, true), INVALID_LOC, INVALID_LOC)

    action6 = Placement(bA1_loc, bA1)
    @test action6 in validactions(board)
    do_action(board, action6)
    test_board_state(board, 7, WHITE, 4, MVector{2,Bool}(true, true), INVALID_LOC, INVALID_LOC)

    show(board)

    action7 = Move(wA1_loc, apply_direction(wS1_loc, Direction.NW))
    @test action7 in validactions(board)
    do_action(board, action7)
    test_board_state(
        board,
        8,
        BLACK,
        4,
        MVector{2,Bool}(true, true),
        apply_direction(wS1_loc, Direction.NW),
        INVALID_LOC,
    )

    action8 = Move(bA1_loc, apply_direction(bS1_loc, Direction.NE))
    @test action8 in validactions(board)
    do_action(board, action8)
    test_board_state(
        board,
        9,
        WHITE,
        5,
        MVector{2,Bool}(true, true),
        apply_direction(bS1_loc, Direction.NE),
        INVALID_LOC,
    )

    action9 = Placement(wS2_loc, wS2)
    @test action9 in validactions(board)
    do_action(board, action9)
    test_board_state(board, 10, BLACK, 5, MVector{2,Bool}(true, true), INVALID_LOC, INVALID_LOC)
end

@testitem "Test climb moves and underworld" begin end
