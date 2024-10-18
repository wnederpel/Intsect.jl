
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
    test_board_state(board, 2, BLACK, 1, MVector{2,Bool}(false, false), wS1_loc, INVALID_LOC)

    action2 = Placement(bS1_loc, bS1)
    @test action2 in validactions(board)
    do_action(board, action2)
    test_board_state(board, 3, WHITE, 2, MVector{2,Bool}(false, false), bS1_loc, INVALID_LOC)

    action3 = Placement(wQ_loc, wQ)
    @test action3 in validactions(board)
    do_action(board, action3)
    test_board_state(board, 4, BLACK, 2, MVector{2,Bool}(false, true), wQ_loc, INVALID_LOC)

    action4 = Placement(bQ_loc, bQ)
    @test action4 in validactions(board)
    do_action(board, action4)
    test_board_state(board, 5, WHITE, 3, MVector{2,Bool}(true, true), bQ_loc, INVALID_LOC)

    action5 = Placement(wA1_loc, wA1)
    @test action5 in validactions(board)
    do_action(board, action5)
    test_board_state(board, 6, BLACK, 3, MVector{2,Bool}(true, true), wA1_loc, INVALID_LOC)

    action6 = Placement(bA1_loc, bA1)
    @test action6 in validactions(board)
    do_action(board, action6)
    test_board_state(board, 7, WHITE, 4, MVector{2,Bool}(true, true), bA1_loc, INVALID_LOC)

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
    test_board_state(board, 10, BLACK, 5, MVector{2,Bool}(true, true), wS2_loc, INVALID_LOC)
end

@testitem "Test undo action" begin
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
    test_board_state(board, 2, BLACK, 1, MVector{2,Bool}(false, false), wS1_loc, INVALID_LOC)

    action2 = Placement(bS1_loc, bS1)
    @test action2 in validactions(board)
    do_action(board, action2)
    test_board_state(board, 3, WHITE, 2, MVector{2,Bool}(false, false), bS1_loc, INVALID_LOC)
    undo(board)
    test_board_state(board, 2, BLACK, 1, MVector{2,Bool}(false, false), wS1_loc, INVALID_LOC)
    do_action(board, action2)

    action3 = Placement(wQ_loc, wQ)
    @test action3 in validactions(board)
    do_action(board, action3)
    test_board_state(board, 4, BLACK, 2, MVector{2,Bool}(false, true), wQ_loc, INVALID_LOC)
    undo(board)
    test_board_state(board, 3, WHITE, 2, MVector{2,Bool}(false, false), bS1_loc, INVALID_LOC)
    do_action(board, action3)

    action4 = Placement(bQ_loc, bQ)
    @test action4 in validactions(board)
    do_action(board, action4)
    test_board_state(board, 5, WHITE, 3, MVector{2,Bool}(true, true), bQ_loc, INVALID_LOC)
    undo(board)
    test_board_state(board, 4, BLACK, 2, MVector{2,Bool}(false, true), wQ_loc, INVALID_LOC)
    do_action(board, action4)

    action5 = Placement(wA1_loc, wA1)
    @test action5 in validactions(board)
    do_action(board, action5)
    test_board_state(board, 6, BLACK, 3, MVector{2,Bool}(true, true), wA1_loc, INVALID_LOC)
    undo(board)
    test_board_state(board, 5, WHITE, 3, MVector{2,Bool}(true, true), bQ_loc, INVALID_LOC)
    do_action(board, action5)

    action6 = Placement(bA1_loc, bA1)
    @test action6 in validactions(board)
    do_action(board, action6)
    test_board_state(board, 7, WHITE, 4, MVector{2,Bool}(true, true), bA1_loc, INVALID_LOC)
    undo(board)
    test_board_state(board, 6, BLACK, 3, MVector{2,Bool}(true, true), wA1_loc, INVALID_LOC)
    do_action(board, action6)

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
    undo(board)
    test_board_state(board, 7, WHITE, 4, MVector{2,Bool}(true, true), bA1_loc, INVALID_LOC)
    do_action(board, action7)

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
    undo(board)
    test_board_state(
        board,
        8,
        BLACK,
        4,
        MVector{2,Bool}(true, true),
        apply_direction(wS1_loc, Direction.NW),
        INVALID_LOC,
    )
    do_action(board, action8)

    action9 = Placement(wS2_loc, wS2)
    @test action9 in validactions(board)
    do_action(board, action9)
    test_board_state(board, 10, BLACK, 5, MVector{2,Bool}(true, true), wS2_loc, INVALID_LOC)
    undo(board)
    test_board_state(
        board,
        9,
        WHITE,
        5,
        MVector{2,Bool}(true, true),
        apply_direction(bS1_loc, Direction.NE),
        INVALID_LOC,
    )
    do_action(board, action9)
end

@testitem "Test pinned tiles" begin
    # Define all pieces
    wS1 = get_tile_from_string("wS1")
    bS1 = get_tile_from_string("bS1")
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")
    wA1 = get_tile_from_string("wA1")
    bA1 = get_tile_from_string("bA1")
    bA2 = get_tile_from_string("bA2")
    wS2 = get_tile_from_string("wS2")
    bA3 = get_tile_from_string("bA3")
    wA2 = get_tile_from_string("wA2")

    # Define their locs
    wS1_loc = MID
    bS1_loc = apply_direction(wS1_loc, Direction.E)
    wQ_loc = apply_direction(wS1_loc, Direction.W)
    bQ_loc = apply_direction(bS1_loc, Direction.E)
    wA1_loc = apply_direction(wQ_loc, Direction.W)
    bA1_loc = apply_direction(bQ_loc, Direction.E)
    wS2_loc = apply_direction(wQ_loc, Direction.W)
    bA2_loc = apply_direction(apply_direction(bQ_loc, Direction.NW), Direction.NW)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    # Do the actions and check the board state 
    action1 = Placement(wS1_loc, wS1)
    do_action(board, action1)

    action2 = Placement(bS1_loc, bS1)
    do_action(board, action2)

    action3 = Placement(wQ_loc, wQ)
    do_action(board, action3)

    action4 = Placement(bQ_loc, bQ)
    do_action(board, action4)

    action5 = Placement(wA1_loc, wA1)
    do_action(board, action5)

    action6 = Placement(bA1_loc, bA1)
    do_action(board, action6)

    action7 = Move(wA1_loc, apply_direction(wS1_loc, Direction.NW))
    wA1_loc = apply_direction(wS1_loc, Direction.NW)
    do_action(board, action7)

    action8 = Move(bA1_loc, apply_direction(bS1_loc, Direction.NE))
    bA1_loc = apply_direction(bS1_loc, Direction.NE)
    do_action(board, action8)

    action9 = Placement(wS2_loc, wS2)
    do_action(board, action9)

    # Test pinned tiles
    is_pinned = get_pinned_tiles(board)
    @test is_pinned[wS1_loc + 1] == true
    @test is_pinned[bS1_loc + 1] == true
    @test is_pinned[wQ_loc + 1] == true
    @test is_pinned[bQ_loc + 1] == false
    @test is_pinned[wA1_loc + 1] == false
    @test is_pinned[bA1_loc + 1] == false
    @test is_pinned[wS2_loc + 1] == false

    action10 = Placement(bA2_loc, bA2)
    do_action(board, action10)

    action11 = Move(wS2_loc, apply_direction(wA1_loc, Direction.NE))
    wS2_loc = apply_direction(wA1_loc, Direction.NE)
    do_action(board, action11)

    is_pinned = get_pinned_tiles(board)
    @test is_pinned[wS1_loc + 1] == false
    @test is_pinned[bS1_loc + 1] == false
    @test is_pinned[wQ_loc + 1] == false
    @test is_pinned[bQ_loc + 1] == false
    @test is_pinned[wA1_loc + 1] == false
    @test is_pinned[bA1_loc + 1] == false
    @test is_pinned[wS2_loc + 1] == false
    @test is_pinned[bA2_loc + 1] == false

    bA3_loc = apply_direction(bA2_loc, Direction.NE)
    action12 = Placement(bA3_loc, bA3)
    do_action(board, action12)

    wA2_loc = apply_direction(wS2_loc, Direction.NW)
    action12 = Placement(wA2_loc, wA2)
    do_action(board, action12)

    is_pinned = get_pinned_tiles(board)
    @test is_pinned[wS1_loc + 1] == false
    @test is_pinned[bS1_loc + 1] == false
    @test is_pinned[wQ_loc + 1] == false
    @test is_pinned[bQ_loc + 1] == false
    @test is_pinned[wA1_loc + 1] == false
    @test is_pinned[bA1_loc + 1] == false
    @test is_pinned[wS2_loc + 1] == true
    @test is_pinned[bA2_loc + 1] == true
    @test is_pinned[bA3_loc + 1] == false
    @test is_pinned[wA2_loc + 1] == false
end

@testitem "Test climb moves and underworld" begin
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    wB1 = get_tile_from_string("wB1")
    bG1 = get_tile_from_string("bG1")
    wA1 = get_tile_from_string("wA1")
    wS1 = get_tile_from_string("wS1")
    bG2 = get_tile_from_string("bG2")
    bG3 = get_tile_from_string("bG3")
    bS1 = get_tile_from_string("bS1")

    board = handle_newgame_command(Gametype.MLP)

    do_action(board, action_from_move_string(board, "wA1"))
    do_action(board, action_from_move_string(board, "bG1 wA1\\"))

    do_action(board, action_from_move_string(board, "wQ -wA1"))
    do_action(board, action_from_move_string(board, "bQ bG1-"))

    do_action(board, action_from_move_string(board, "wS1 \\wA1"))
    do_action(board, action_from_move_string(board, "bG2 bQ-"))

    do_action(board, action_from_move_string(board, "wB1 wS1-"))
    do_action(board, action_from_move_string(board, "bG3 bG2-"))

    show(board)
    do_action(board, action_from_move_string(board, "wB1 \\wA1"))
    @test first(board.underworld[get_loc(board, wB1)]) == wS1
    @test isempty(board.underworld[get_loc(board, bS1)])
    do_action(board, action_from_move_string(board, "bS1 bG3-"))

    do_action(board, action_from_move_string(board, "wB1 \\wQ"))
    @test isempty(board.underworld[get_loc(board, wB1)])
end

@testitem "Pillbug special moves are valid, even when the pillbug is stuck" begin
    board = handle_newgame_command(Gametype.MLP)

    do_action(board, action_from_move_string(board, "wP"))
    do_action(board, action_from_move_string(board, "bS1 wP-"))

    do_action(board, action_from_move_string(board, "wQ -wP"))
    do_action(board, action_from_move_string(board, "bQ bS1-"))

    @test length(validactions(board)) == 34
    @test count(action -> action isa Move, validactions(board)) == 4
end

@testitem "Pillbug special moves for mosquito are valid, even when the pillbug and mosquito are stuck" begin
    board = handle_newgame_command(Gametype.MLP)

    do_action(board, action_from_move_string(board, "wM"))
    do_action(board, action_from_move_string(board, "bP wM-"))

    do_action(board, action_from_move_string(board, "wQ -wM"))
    do_action(board, action_from_move_string(board, "bQ bP-"))

    @test length(validactions(board)) == 34
    @test count(action -> action isa Move, validactions(board)) == 4
end