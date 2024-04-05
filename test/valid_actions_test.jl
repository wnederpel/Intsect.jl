@testitem "Only the first bug of a kind can be placed" begin
    wQ = get_tile_from_string("wQ")

    wQ_loc = MID

    board = handle_newgame_command(Gametype.MLP)
    set_tile_on_board(board, wQ_loc, wQ)
    set_loc(board, wQ, wQ_loc)

    actions = validactions(board)
    @test count(action -> action isa Placement, actions) == 7 * 6
end

@testitem "The white queen must be placed on the fourth move at the latest" begin
    wL = get_tile_from_string("wL")
    wQ = get_tile_from_string("wQ")

    wL_loc = MID

    board = handle_newgame_command(Gametype.MLP)
    board.turn = 4

    set_tile_on_board(board, wL_loc, wL)
    set_loc(board, wL, wL_loc)

    actions = validactions(board)
    @test length(actions) == 1 * 6
    @test all(action -> action isa Placement, actions)
    @test all(action -> action.tile == wQ, actions)
end

@testitem "The black queen must be placed on the fourth move at the latest" begin
    wL = get_tile_from_string("wL")
    bL = get_tile_from_string("bL")
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")

    wL_loc = MID
    bL_loc = apply_direction(wL_loc, Direction.E)

    board = handle_newgame_command(Gametype.MLP)
    board.turn = 4
    board.current_color = BLACK

    set_tile_on_board(board, wL_loc, wL)
    set_loc(board, wL, wL_loc)
    set_loc(board, bL, bL_loc)

    actions = validactions(board)
    @test length(actions) == 1 * 3
    @test all(action -> action isa Placement, actions)
    @test all(action -> action.tile == bQ, actions)
end

@testitem "The queen cannot be placed as the first move" begin
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")

    wQ_loc = MID

    board = handle_newgame_command(Gametype.MLP)

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

    board = handle_newgame_command(Gametype.MLP)
    set_tile_on_board(board, wL_loc, wL)
    set_loc(board, wL, wL_loc)
    board.ply += 1
    set_tile_on_board(board, bL_loc, bL)
    set_loc(board, bL, bL_loc)
    board.ply += 1
    board.turn += 1

    actions = validactions(board)
    @test all(actions -> actions isa Placement, actions)

    set_tile_on_board(board, wQ_loc, wQ)
    set_loc(board, wQ, wQ_loc)
    board.queen_placed[WHITE] = true

    actions = validactions(board)
    @test any(actions -> actions isa Move, actions)
    @test any(actions -> actions isa Placement, actions)
end

@testitem "The piece moved by the pillbug cannot be moved the next turn" begin end