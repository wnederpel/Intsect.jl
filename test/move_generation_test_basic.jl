@testitem "Queen movement basic" begin
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    bA1 = get_tile_from_string("bA1")
    wS1 = get_tile_from_string("wS1")
    bS1 = get_tile_from_string("bS1")
    wQ = get_tile_from_string("wQ")
    wA1 = get_tile_from_string("wA1")
    wG1 = get_tile_from_string("wG1")
    bG1 = get_tile_from_string("bG1")

    # Define their locs
    bQ_loc = MID - 1
    bA1_loc = apply_direction(bQ_loc, Direction.NE)
    wS1_loc = apply_direction(bA1_loc, Direction.E)
    bS1_loc = apply_direction(wS1_loc, Direction.SE)
    wQ_loc = apply_direction(bS1_loc, Direction.SW)
    wA1_loc = apply_direction(wQ_loc, Direction.SW)
    wG1_loc = apply_direction(wA1_loc, Direction.W)
    bG1_loc = apply_direction(wG1_loc, Direction.NW)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, bA1_loc, bA1)
    set_tile_on_board(board, wS1_loc, wS1)
    set_tile_on_board(board, bS1_loc, bS1)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wA1_loc, wA1)
    set_tile_on_board(board, wG1_loc, wG1)
    set_tile_on_board(board, bG1_loc, bG1)

    # Generate the moves
    move_set = HexSet()
    queenmoves(board, bQ_loc, move_set)

    # Check the moves
    @test move_set[apply_direction(bQ_loc, Direction.E)]
    @test move_set[apply_direction(bQ_loc, Direction.SE)]
    @test move_set[apply_direction(bQ_loc, Direction.W)]
    @test move_set[apply_direction(bQ_loc, Direction.NW)]
    @test count_ones(move_set) == 4
end

@testitem "Grasshopper movement basic" begin
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    bA1 = get_tile_from_string("bA1")
    wA1 = get_tile_from_string("wA1")
    wS1 = get_tile_from_string("wS1")
    wG1 = get_tile_from_string("wG1")
    bG1 = get_tile_from_string("bG1")
    bS1 = get_tile_from_string("bS1")
    bB1 = get_tile_from_string("bB1")
    bS2 = get_tile_from_string("bS2")
    wS2 = get_tile_from_string("wS2")
    wQ = get_tile_from_string("wQ")
    wB1 = get_tile_from_string("wB1")

    # Define their locs
    wQ_loc = MID
    wS1_loc = apply_direction(wQ_loc, Direction.E)
    wA1_loc = apply_direction(wS1_loc, Direction.E)
    bA1_loc = apply_direction(wA1_loc, Direction.NE)
    bQ_loc = apply_direction(bA1_loc, Direction.NW)
    wG1_loc = apply_direction(bQ_loc, Direction.W)
    bG1_loc = apply_direction(wG1_loc, Direction.SW)
    wB1_loc = apply_direction(wG1_loc, Direction.W)
    bB1_loc = apply_direction(wQ_loc, Direction.SE)
    bS1_loc = apply_direction(bB1_loc, Direction.SW)
    wS2_loc = apply_direction(bS1_loc, Direction.W)
    bS2_loc = apply_direction(wS1_loc, Direction.NW)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, bA1_loc, bA1)
    set_tile_on_board(board, wS1_loc, wS1)
    set_tile_on_board(board, bS1_loc, bS1)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wA1_loc, wA1)
    set_tile_on_board(board, wG1_loc, wG1)
    set_tile_on_board(board, bG1_loc, bG1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, bS2_loc, bS2)
    set_tile_on_board(board, wS2_loc, wS2)
    set_tile_on_board(board, wB1_loc, wB1)

    # Generate the moves
    move_set = HexSet()
    grasshoppermoves(board, wG1_loc, move_set)

    # Check the moves
    @test move_set[apply_direction(bQ_loc, Direction.E)]
    @test move_set[apply_direction(wB1_loc, Direction.W)]
    @test move_set[apply_direction(wQ_loc, Direction.SW)]
    @test count_ones(move_set) == 3
end

@testitem "Spider movement basic" begin
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    wS1 = get_tile_from_string("wS1")
    bS1 = get_tile_from_string("bS1")
    bA1 = get_tile_from_string("bA1")
    wA1 = get_tile_from_string("wA1")
    wG1 = get_tile_from_string("wG1")
    bG1 = get_tile_from_string("bG1")
    wB1 = get_tile_from_string("wB1")
    bB1 = get_tile_from_string("bB1")

    # Define their locs
    bQ_loc = MID - 1
    bA1_loc = apply_direction(bQ_loc, Direction.NE)
    wB1_loc = apply_direction(bA1_loc, Direction.NE)
    wG1_loc = apply_direction(bQ_loc, Direction.SE)
    bG1_loc = apply_direction(wG1_loc, Direction.E)
    wA1_loc = apply_direction(bG1_loc, Direction.E)
    bB1_loc = apply_direction(wA1_loc, Direction.NE)
    wQ_loc = apply_direction(bB1_loc, Direction.NE)
    wS1_loc = apply_direction(wQ_loc, Direction.NW)
    bS1_loc = apply_direction(wS1_loc, Direction.NW)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, bA1_loc, bA1)
    set_tile_on_board(board, wS1_loc, wS1)
    set_tile_on_board(board, bS1_loc, bS1)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wA1_loc, wA1)
    set_tile_on_board(board, wG1_loc, wG1)
    set_tile_on_board(board, bG1_loc, bG1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, wB1_loc, wB1)

    # Generate the moves
    move_set = HexSet()
    spidermoves(board, bS1_loc, move_set)

    # Check the moves
    @test move_set[apply_direction(wQ_loc, Direction.E)]
    @test move_set[apply_direction(wB1_loc, Direction.NW)]
    @test move_set[apply_direction(bQ_loc, Direction.E)]
    @test move_set[apply_direction(bB1_loc, Direction.W)]
    @test count_ones(move_set) == 4
end

@testitem "Ant movement basic" begin
    # Define all pieces
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
    move_set = HexSet()
    antmoves(board, bA1_loc, move_set)

    # Check the moves
    @test move_set[apply_direction(bB1_loc, Direction.E)]
    @test move_set[apply_direction(bB1_loc, Direction.SE)]
    @test move_set[apply_direction(wQ_loc, Direction.E)]
    @test move_set[apply_direction(wQ_loc, Direction.NE)]
    @test move_set[apply_direction(wQ_loc, Direction.NW)]
    @test move_set[apply_direction(bQ_loc, Direction.NE)]
    @test move_set[apply_direction(bQ_loc, Direction.NW)]
    @test move_set[apply_direction(bQ_loc, Direction.W)]
    @test move_set[apply_direction(wG1_loc, Direction.W)]
    @test move_set[apply_direction(wB1_loc, Direction.W)]
    @test move_set[apply_direction(bA1_loc, Direction.W)]
    @test count_ones(move_set) == 11
end

@testitem "Beetle movement basic" begin
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    wB1 = get_tile_from_string("wB1")
    bG1 = get_tile_from_string("bG1")
    wA1 = get_tile_from_string("wA1")
    wS1 = get_tile_from_string("wS1")

    # Define their locs
    bQ_loc = MID - 1
    wA1_loc = apply_direction(bQ_loc, Direction.NW)
    wQ_loc = apply_direction(wA1_loc, Direction.W)
    wS1_loc = apply_direction(wQ_loc, Direction.NE)
    wB1_loc = apply_direction(wS1_loc, Direction.E)
    bG1_loc = apply_direction(bQ_loc, Direction.E)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bG1_loc, bG1)
    set_tile_on_board(board, wA1_loc, wA1)
    set_tile_on_board(board, wS1_loc, wS1)

    # Generate the moves
    move_set = HexSet()
    beetlemoves(board, wB1_loc, 1, move_set)
    # Check the moves
    @test move_set[apply_direction(wB1_loc, Direction.NW)]
    @test move_set[apply_direction(wB1_loc, Direction.SE)]
    @test move_set[apply_direction(wB1_loc, Direction.W)]
    @test move_set[apply_direction(wB1_loc, Direction.SW)]
    @test count_ones(move_set) == 4

    do_action(board, Move(wB1_loc, apply_direction(wB1_loc, Direction.NW)))
    wB1_loc = apply_direction(wB1_loc, Direction.NW)

    move_set = HexSet()
    beetlemoves(board, wB1_loc, 2, move_set)
    # Comment text text
    @test move_set[apply_direction(wB1_loc, Direction.NW)]
    @test move_set[apply_direction(wB1_loc, Direction.SE)]
    @test move_set[apply_direction(wB1_loc, Direction.W)]
    @test move_set[apply_direction(wB1_loc, Direction.E)]
    @test move_set[apply_direction(wB1_loc, Direction.SW)]
    @test move_set[apply_direction(wB1_loc, Direction.NE)]
    @test count_ones(move_set) == 6
end

@testitem "Ladybug movement basic" begin
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    wB1 = get_tile_from_string("wB1")
    wG1 = get_tile_from_string("wG1")
    wL1 = get_tile_from_string("wL1")
    bB1 = get_tile_from_string("bB1")

    # Define their locs
    bQ_loc = MID - 1
    wG1_loc = apply_direction(bQ_loc, Direction.SW)
    wB1_loc = apply_direction(wG1_loc, Direction.SE)
    wL1_loc = apply_direction(wB1_loc, Direction.SE)
    bB1_loc = apply_direction(wL1_loc, Direction.NE)
    wQ_loc = apply_direction(bB1_loc, Direction.NE)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, wG1_loc, wG1)
    set_tile_on_board(board, wL1_loc, wL1)
    set_tile_on_board(board, bB1_loc, bB1)

    # Generate the moves
    move_set = HexSet()
    ladybugmoves(board, wL1_loc, move_set)

    # Check the moves
    @test move_set[apply_direction(wL1_loc, Direction.E)]
    @test move_set[apply_direction(bB1_loc, Direction.E)]
    @test move_set[apply_direction(wQ_loc, Direction.E)]
    @test move_set[apply_direction(wQ_loc, Direction.NE)]
    @test move_set[apply_direction(wQ_loc, Direction.W)]
    @test move_set[apply_direction(wQ_loc, Direction.NW)]
    @test move_set[apply_direction(wL1_loc, Direction.W)]
    @test move_set[apply_direction(wB1_loc, Direction.W)]
    @test move_set[apply_direction(wG1_loc, Direction.W)]
    @test move_set[apply_direction(bQ_loc, Direction.W)]
    @test count_ones(move_set) == 10
end

@testitem "Mosquito movement basic" begin
    using DataStructures
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    wB1 = get_tile_from_string("wB1")
    bS1 = get_tile_from_string("bS1")
    wM = get_tile_from_string("wM")

    # Define their locs
    bQ_loc = MID - 1
    wQ_loc = apply_direction(bQ_loc, Direction.SE)
    wB1_loc = apply_direction(wQ_loc, Direction.W)
    wM_loc = apply_direction(wB1_loc, Direction.SW)
    bS1_loc = apply_direction(wM_loc, Direction.NW)

    # Create the board
    board = handle_newgame_command(MLPGame)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bS1_loc, bS1)
    set_tile_on_board(board, wM_loc, wM)

    # Generate the moves
    move_set = HexSet()
    mosquitomoves(board, wM_loc, 1, DefaultDict(false), move_set)

    # Check the moves
    @test move_set[apply_direction(wM_loc, Direction.W)]
    @test move_set[apply_direction(wM_loc, Direction.E)]
    @test move_set[apply_direction(wM_loc, Direction.NE)]
    @test move_set[apply_direction(wM_loc, Direction.NW)]
    @test move_set[apply_direction(wQ_loc, Direction.E)]
    @test move_set[apply_direction(bS1_loc, Direction.NW)]
    @test count_ones(move_set) == 6
end

@testitem "Pillbug movement basic" begin
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

    # Setup dict of pinned pieces
    ispinned = DefaultDict(false)
    ispinned[wS1_loc] = true

    # Generate the moves
    move_to_set = HexSet()
    throw_to_set = HexSet()
    throw_from_set = HexSet()

    pillbugmoves_normal(board, wP_loc, ispinned, move_to_set)
    pillbugmoves_throw(board, wP_loc, ispinned, throw_from_set, throw_to_set)

    # Check the moves
    # First the normal moves
    @test move_to_set[apply_direction(wP_loc, Direction.W)]
    @test move_to_set[apply_direction(wP_loc, Direction.SW)]
    # Then the special moves
    @test throw_to_set[apply_direction(wP_loc, Direction.W)]
    @test throw_to_set[apply_direction(wP_loc, Direction.SW)]

    @test throw_from_set[bQ_loc]
    @test throw_from_set[bA1_loc]
    @test throw_from_set[wQ_loc]
end
