@testitem "Only the first bug of a kind can be placed" begin
    wQ = get_tile_from_string("wQ")

    wQ_loc = MID

    board = handle_newgame_command(MLPGame)
    set_tile_on_board(board, wQ_loc, wQ)
    set_loc(board, wQ, wQ_loc)
    board.ply += 1
    board.current_color = BLACK

    actions = validactions(board)
    @test count(action -> action isa Placement, actions) == 7 * 6
end

@testitem "The white queen must be placed on the fourth move at the latest" begin
    wQ = get_tile_from_string("wQ")

    board = handle_newgame_command(MLPGame)

    do_action(board, "wL")
    do_action(board, "bL wL-")

    do_action(board, "wP -wL")
    do_action(board, "bP bL-")

    do_action(board, "wA1 -wP")
    do_action(board, "bA1 bP-")

    actions = validactions(board)
    @test all(action -> action isa Placement, actions)
    @test all(action -> action.tile == wQ, actions)
end

@testitem "The black queen must be placed on the fourth move at the latest" begin
    bQ = get_tile_from_string("bQ")

    board = handle_newgame_command(MLPGame)

    do_action(board, "wL")
    do_action(board, "bL wL-")

    do_action(board, "wP -wL")
    do_action(board, "bP bL-")

    do_action(board, "wA1 -wP")
    do_action(board, "bA1 bP-")
    do_action(board, "wQ -wA1")

    actions = validactions(board)
    @test all(action -> action isa Placement, actions)
    @test all(action -> action.tile == bQ, actions)
end

@testitem "The queen cannot be placed as the first move" begin
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")

    wQ_loc = MID

    board = handle_newgame_command(MLPGame)

    actions = validactions(board)
    @test length(actions) == 7
    @test all(action -> action isa Placement, actions)
    @test all(action -> action.tile != wQ, actions)
    @test all(action -> action.goal_loc == MID, actions)

    set_tile_on_board(board, wQ_loc, wQ)
    set_loc(board, wQ, wQ_loc)
    board.ply += 1
    board.current_color = BLACK

    actions = validactions(board)
    @test length(actions) == 7 * 6
    @test all(action -> action isa Placement, actions)
    @test all(action -> action.tile != bQ, actions)
end

@testitem "no moves can be made before the queen is placed" begin
    wL = get_tile_from_string("wL")
    bL = get_tile_from_string("bL")
    wQ = get_tile_from_string("wQ")

    wL_loc = MID
    bL_loc = apply_direction(wL_loc, Direction.E)
    wQ_loc = apply_direction(wL_loc, Direction.W)

    board = handle_newgame_command(MLPGame)

    do_action(board, action_from_move_string(board, "wL"))
    do_action(board, action_from_move_string(board, "bL wL-"))

    @test all(actions -> actions isa Placement, validactions(board))
end

@testitem "The tile moved by the pillbug cannot be moved the next turn" begin
    # Define all tiles
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    wG1 = get_tile_from_string("wG1")
    wB1 = get_tile_from_string("wB1")
    bB1 = get_tile_from_string("bB1")
    bA1 = get_tile_from_string("bA1")

    # Define their locs
    bQ_loc = MID - 1
    wG1_loc = apply_direction(bQ_loc, Direction.SW)
    wB1_loc = apply_direction(wG1_loc, Direction.SE)
    bA1_loc = apply_direction(wB1_loc, Direction.SE)
    bB1_loc = apply_direction(bA1_loc, Direction.NE)
    wQ_loc = apply_direction(bB1_loc, Direction.NE)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wG1_loc, wG1)
    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, bA1_loc, bA1)

    # Generate the moves
    actions = validactions(board)

    bA1_moves = filter(action -> action isa Move && action.moving_loc == bA1_loc, actions)

    @test isempty(bA1_moves)
end

@testitem "The tile that just moved cannot be moved by the pillbug" begin
    using DataStructures

    # Define all pieces
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    bB1 = get_tile_from_string("bB1")
    wS1 = get_tile_from_string("wS1")
    wP = get_tile_from_string("wP")
    bA1 = get_tile_from_string("bA1")

    # Define their locs
    bQ_loc = MID - 1
    wP_loc = apply_direction(bQ_loc, Direction.SE)
    wQ_loc = apply_direction(wP_loc, Direction.SE)
    bA1_loc = apply_direction(wQ_loc, Direction.NE)
    wS1_loc = apply_direction(bA1_loc, Direction.NW)
    bB1_loc = apply_direction(wS1_loc, Direction.NE)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wP_loc, wP)
    set_tile_on_board(board, bA1_loc, bA1)
    set_tile_on_board(board, wS1_loc, wS1)
    set_tile_on_board(board, bB1_loc, bB1)

    board.just_moved_loc = bA1_loc

    # Setup dict of pinned pieces
    ispinned = DefaultDict(false)
    ispinned[wS1_loc] = true

    # Generate the moves
    pillbugmoves(board, wP_loc, ispinned, board.validactions)
    moves = extract_valid_actions(board)

    # Check the moves
    # First the normal moves
    @test Move(wP_loc, apply_direction(wP_loc, Direction.W)) in moves
    @test Move(wP_loc, apply_direction(wP_loc, Direction.SW)) in moves
    # Then the special moves
    @test Move(bQ_loc, apply_direction(wP_loc, Direction.W)) in moves
    @test Move(bQ_loc, apply_direction(wP_loc, Direction.SW)) in moves
    @test Move(wQ_loc, apply_direction(wP_loc, Direction.W)) in moves
    @test Move(wQ_loc, apply_direction(wP_loc, Direction.SW)) in moves
    @test length(moves) == 6
end