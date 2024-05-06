@testitem "Beetle movement on top of hive" begin
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    # Add one height to the beetles
    wB1 = get_tile_from_string("wB1") + 0b00000001
    bB1 = get_tile_from_string("bB1") + 0b00000001
    # Pieces for underneath the beetles
    wS1 = get_tile_from_string("wS1")
    bS1 = get_tile_from_string("bS1")

    # Define their locs
    bQ_loc = MID - 1
    wQ_loc = apply_direction(bQ_loc, Direction.E)
    wB1_loc = apply_direction(bQ_loc, Direction.NE)
    bB1_loc = apply_direction(bQ_loc, Direction.SE)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bB1_loc, bB1)
    push!(board.underworld[wB1_loc], wS1)
    push!(board.underworld[bB1_loc], bS1)

    # Generate the moves
    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    climbs = Vector{Climb}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    climb_index = 1
    move_index, climb_index = beetlemoves(
        board, bB1_loc, get_tile_height(bB1), moves, move_index, climbs, climb_index
    )

    # Check the moves
    @test Climb(bB1_loc, apply_direction(bB1_loc, Direction.NE)) in climbs
    @test Climb(bB1_loc, apply_direction(bB1_loc, Direction.NW)) in climbs
    @test Climb(bB1_loc, apply_direction(bB1_loc, Direction.E)) in climbs
    @test Climb(bB1_loc, apply_direction(bB1_loc, Direction.SE)) in climbs
    @test Climb(bB1_loc, apply_direction(bB1_loc, Direction.W)) in climbs
    @test Climb(bB1_loc, apply_direction(bB1_loc, Direction.SW)) in climbs
    @test climb_index - 1 == 6
    @test move_index - 1 == 0
end

@testitem "Sliding between stacked pieces" begin
    # Define all pieces
    wB1 = get_tile_from_string("wB1")
    bB1 = get_tile_from_string("bB1")
    wB2 = get_tile_from_string("wB2") + 0b00000001
    bB2 = get_tile_from_string("bB2") + 0b00000001

    # Define their locs
    wB1_loc = MID - 1
    bB1_loc = apply_direction(wB1_loc, Direction.E)
    wB2_loc = apply_direction(wB1_loc, Direction.NE)
    bB2_loc = apply_direction(wB1_loc, Direction.SE)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, wB2_loc, wB2)
    set_tile_on_board(board, bB2_loc, bB2)

    # Generate the moves
    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    climbs = Vector{Climb}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    climb_index = 1
    move_index, climb_index = beetlemoves(
        board, wB1_loc, get_tile_height(wB1), moves, move_index, climbs, climb_index
    )

    # Check the moves
    # wB1 cammot move to bB1_loc
    @test Climb(wB1_loc, apply_direction(wB1_loc, Direction.NE)) in climbs
    @test Climb(wB1_loc, apply_direction(wB1_loc, Direction.SE)) in climbs
    @test Move(wB1_loc, apply_direction(wB1_loc, Direction.NW)) in moves
    @test Move(wB1_loc, apply_direction(wB1_loc, Direction.SW)) in moves
    @test move_index - 1 == 2
    @test climb_index - 1 == 2

    # If bB1 is one lvl higher, this does work, as wB1 goes up to the lvl above  bB1
    wB1 = get_tile_from_string("wB1")
    bB1 = get_tile_from_string("bB1") + 0b00000001
    wB2 = get_tile_from_string("wB2") + 0b00000001
    bB2 = get_tile_from_string("bB2") + 0b00000001

    # Define their locs
    wB1_loc = MID - 1
    bB1_loc = apply_direction(wB1_loc, Direction.E)
    wB2_loc = apply_direction(wB1_loc, Direction.NE)
    bB2_loc = apply_direction(wB1_loc, Direction.SE)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, wB2_loc, wB2)
    set_tile_on_board(board, bB2_loc, bB2)

    # Generate the moves
    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    climbs = Vector{Climb}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    climb_index = 1
    move_index, climb_index = beetlemoves(
        board, wB1_loc, get_tile_height(wB1), moves, move_index, climbs, climb_index
    )

    # Check the moves
    @test Climb(wB1_loc, apply_direction(wB1_loc, Direction.E)) in climbs

    # If wB1 is one lvl higher, this does not work as the other pieces still block the sliding
    wB1 = get_tile_from_string("wB1") + 0b00000001
    bB1 = get_tile_from_string("bB1")
    wB2 = get_tile_from_string("wB2") + 0b00000001
    bB2 = get_tile_from_string("bB2") + 0b00000001

    # Define their locs
    wB1_loc = MID - 1
    bB1_loc = apply_direction(wB1_loc, Direction.E)
    wB2_loc = apply_direction(wB1_loc, Direction.NE)
    bB2_loc = apply_direction(wB1_loc, Direction.SE)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, wB2_loc, wB2)
    set_tile_on_board(board, bB2_loc, bB2)

    # Generate the moves
    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    climbs = Vector{Climb}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    climb_index = 1
    move_index, climb_index = beetlemoves(
        board, wB1_loc, get_tile_height(wB1), moves, move_index, climbs, climb_index
    )

    # Check the moves
    # wB1 still cammot move to bB1_loc as it needs to be two higher
    @test !(Climb(wB1_loc, apply_direction(wB1_loc, Direction.E)) in moves)

    # If wB1 is two lvls higher, this does work as it can slide
    wB1 = get_tile_from_string("wB1") + 0b00000010
    bB1 = get_tile_from_string("bB1")
    wB2 = get_tile_from_string("wB2") + 0b00000001
    bB2 = get_tile_from_string("bB2") + 0b00000001

    # Define their locs
    wB1_loc = MID - 1
    bB1_loc = apply_direction(wB1_loc, Direction.E)
    wB2_loc = apply_direction(wB1_loc, Direction.NE)
    bB2_loc = apply_direction(wB1_loc, Direction.SE)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, wB2_loc, wB2)
    set_tile_on_board(board, bB2_loc, bB2)

    # Generate the moves
    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    climbs = Vector{Climb}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    climb_index = 1
    move_index, climb_index = beetlemoves(
        board, wB1_loc, get_tile_height(wB1), moves, move_index, climbs, climb_index
    )

    # Check the moves
    # wB1 still cammot move to bB1_loc as it needs to be two higher
    @test Climb(wB1_loc, apply_direction(wB1_loc, Direction.E)) in climbs
end

@testitem "Mosquito cannot move when it only touches a mosquito" begin
    # Define all pieces
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")
    wM = get_tile_from_string("wM")
    bM = get_tile_from_string("bM")

    # Define their locs
    wQ_loc = MID - 1
    bQ_loc = apply_direction(wQ_loc, Direction.E)
    wM_loc = apply_direction(bQ_loc, Direction.E)
    bM_loc = apply_direction(wM_loc, Direction.E)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wM_loc, wM)
    set_tile_on_board(board, bM_loc, bM)

    # Generate the moves
    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    climbs = Vector{Climb}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    climb_index = 1
    move_index, climb_index = mosquitomoves(
        board, bM_loc, get_tile_height(bM), nothing, moves, move_index, climbs, climb_index
    )

    # Check the moves
    @test climb_index - 1 == 0
    @test move_index - 1 == 0
end

@testitem "Move to oneself is invalid for spider" begin
    # Define all pieces
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")
    wL = get_tile_from_string("wL")
    wA1 = get_tile_from_string("wA1")
    wA2 = get_tile_from_string("wA2")
    wA3 = get_tile_from_string("wA3")
    bA1 = get_tile_from_string("bA1")
    bA2 = get_tile_from_string("bA2")
    bA3 = get_tile_from_string("bA3")

    wS1 = get_tile_from_string("wS1")

    wQ_loc = MID - 2
    bQ_loc = apply_direction(wQ_loc, Direction.E)
    wL_loc = apply_direction(bQ_loc, Direction.E)
    wA1_loc = apply_direction(wL_loc, Direction.NE)
    wA2_loc = apply_direction(wA1_loc, Direction.NW)
    wA3_loc = apply_direction(wA2_loc, Direction.NW)
    bA1_loc = apply_direction(wA3_loc, Direction.W)
    bA2_loc = apply_direction(bA1_loc, Direction.SW)
    bA3_loc = apply_direction(bA2_loc, Direction.SW)

    wS1_loc = apply_direction(bA3_loc, Direction.E)

    board = handle_newgame_command(Gametype.MLP)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wL_loc, wL)
    set_tile_on_board(board, wA1_loc, wA1)
    set_tile_on_board(board, wA2_loc, wA2)
    set_tile_on_board(board, wA3_loc, wA3)
    set_tile_on_board(board, bA1_loc, bA1)
    set_tile_on_board(board, bA2_loc, bA2)
    set_tile_on_board(board, bA3_loc, bA3)

    set_tile_on_board(board, wS1_loc, wS1)

    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    move_index = spidermoves(board, wS1_loc, moves, move_index)

    @test move_index - 1 == 0

    # Also invalid for ant
    move_index = 1
    move_index = antmoves(board, wS1_loc, moves, move_index)

    @test move_index - 1 == 2
end

@testitem "The board wraps around." begin
    # Define all pieces
    bQ = get_tile_from_string("bQ")
    wQ = get_tile_from_string("wQ")
    wG1 = get_tile_from_string("wG1")
    wB1 = get_tile_from_string("wB1")
    bB1 = get_tile_from_string("bB1")
    bA1 = get_tile_from_string("bA1")

    # Define their locs
    bQ_loc = 1
    wG1_loc = apply_direction(bQ_loc, Direction.SW)
    wB1_loc = apply_direction(wG1_loc, Direction.SE)
    bA1_loc = apply_direction(wB1_loc, Direction.SE)
    bB1_loc = apply_direction(bA1_loc, Direction.NE)
    wQ_loc = apply_direction(bB1_loc, Direction.NE)

    # Create the board
    board = handle_newgame_command(Gametype.MLP)

    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wG1_loc, wG1)
    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, bA1_loc, bA1)

    # Generate the moves
    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    move_index = antmoves(board, bA1_loc, moves, move_index)

    # Check the moves
    @test Move(bA1_loc, apply_direction(bB1_loc, Direction.E)) in moves
    @test Move(bA1_loc, apply_direction(bB1_loc, Direction.SE)) in moves
    @test Move(bA1_loc, apply_direction(wQ_loc, Direction.E)) in moves
    @test Move(bA1_loc, apply_direction(wQ_loc, Direction.NE)) in moves
    @test Move(bA1_loc, apply_direction(wQ_loc, Direction.NW)) in moves
    @test Move(bA1_loc, apply_direction(bQ_loc, Direction.NE)) in moves
    @test Move(bA1_loc, apply_direction(bQ_loc, Direction.NW)) in moves
    @test Move(bA1_loc, apply_direction(bQ_loc, Direction.W)) in moves
    @test Move(bA1_loc, apply_direction(wG1_loc, Direction.W)) in moves
    @test Move(bA1_loc, apply_direction(wB1_loc, Direction.W)) in moves
    @test Move(bA1_loc, apply_direction(bA1_loc, Direction.W)) in moves
    @test move_index - 1 == 11
end

@testitem "Pillbug special moves can fill elbows" begin
    using DataStructures

    wP = get_tile_from_string("wP")
    bP = get_tile_from_string("bP")
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")
    wM = get_tile_from_string("wM")
    bM = get_tile_from_string("bM")

    wP_loc = MID - 1
    wQ_loc = apply_direction(wP_loc, Direction.SW)
    wM_loc = apply_direction(wQ_loc, Direction.NW)

    bP_loc = apply_direction(wP_loc, Direction.E)
    bQ_loc = apply_direction(bP_loc, Direction.NE)
    bM_loc = apply_direction(bQ_loc, Direction.NE)

    board = handle_newgame_command(Gametype.MLP)
    set_tile_on_board(board, wP_loc, wP)
    set_tile_on_board(board, wQ_loc, wQ)
    set_tile_on_board(board, wM_loc, wM)
    set_tile_on_board(board, bP_loc, bP)
    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, bM_loc, bM)

    ispinned = DefaultDict{Int,Bool}(false)
    ispinned[wP_loc + 1] = true
    ispinned[bQ_loc + 1] = true
    ispinned[bP_loc + 1] = true

    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    move_index = pillbugmoves(board, wP_loc, ispinned, moves, move_index)

    @test Move(wQ_loc, apply_direction(wP_loc, Direction.SE)) in moves
    @test Move(wQ_loc, apply_direction(wP_loc, Direction.NE)) in moves
    @test Move(wQ_loc, apply_direction(wP_loc, Direction.NW)) in moves

    @test Move(wM_loc, apply_direction(wP_loc, Direction.SE)) in moves
    @test Move(wM_loc, apply_direction(wP_loc, Direction.NE)) in moves
    @test Move(wM_loc, apply_direction(wP_loc, Direction.NW)) in moves

    @test move_index - 1 == 6
end

@testitem "Pillbug cannot special move through a beetle gate" begin
    using DataStructures

    wP = get_tile_from_string("wP")
    wB1 = get_tile_from_string("wB1") + 0b00000001
    bQ = get_tile_from_string("bQ")
    wM = get_tile_from_string("wM")
    bM = get_tile_from_string("bM")
    bB1 = get_tile_from_string("bB1") + 0b00000001

    wP_loc = MID - 1
    wB1_loc = apply_direction(wP_loc, Direction.SW)
    wM_loc = apply_direction(wB1_loc, Direction.NW)

    bB1_loc = apply_direction(wP_loc, Direction.E)
    bQ_loc = apply_direction(bB1_loc, Direction.NE)
    bM_loc = apply_direction(bQ_loc, Direction.NE)

    board = handle_newgame_command(Gametype.MLP)
    set_tile_on_board(board, wP_loc, wP)
    set_tile_on_board(board, wB1_loc, wB1)
    set_tile_on_board(board, wM_loc, wM)
    set_tile_on_board(board, bB1_loc, bB1)
    set_tile_on_board(board, bQ_loc, bQ)
    set_tile_on_board(board, bM_loc, bM)

    ispinned = DefaultDict{Int,Bool}(false)
    ispinned[wP_loc + 1] = true
    ispinned[bQ_loc + 1] = true
    ispinned[bB1_loc + 1] = true

    moves = Vector{Move}(undef, VALID_BUFFER_SIZE)
    move_index = 1
    move_index = pillbugmoves(board, wP_loc, ispinned, moves, move_index)

    @test Move(wM_loc, apply_direction(wP_loc, Direction.NE)) in moves
    @test Move(wM_loc, apply_direction(wP_loc, Direction.NW)) in moves

    @test move_index - 1 == 2
end

@testitem "Pillbug special moves take into account that a piece sliding on the pill bug might add a possible down sliding move" begin
    # This should never occur, a tile can only make something new possible when it is stacked, and stacked tiles cannot be moved by the pillbug
end
