@testitem "Test placement location generation" begin
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")
    wB1 = get_tile_from_string("wB1") + 0b00000001
    bB1 = get_tile_from_string("bB1") + 0b00000010

    wQ_loc = MID
    wB1_loc = MID - 1
    bQ_loc = MID + 1
    bB1_loc = MID + 2

    board = handle_newgame_command(Gametype.MLP)
    set_tile_on_board(board, wQ_loc, wQ)
    set_loc(board, wQ, wQ_loc)
    set_tile_on_board(board, bQ_loc, bQ)
    set_loc(board, bQ, bQ_loc)
    set_tile_on_board(board, wB1_loc, wB1)
    set_loc(board, wB1, wB1_loc)
    set_tile_on_board(board, bB1_loc, bB1)
    set_loc(board, bB1, bB1_loc)

    white_placement_locs = generate_placement_locs(board, 1)
    black_placement_locs = generate_placement_locs(board, 0)

    @test length(white_placement_locs) == 5
    @test apply_direction(wB1_loc, Direction.NW) in white_placement_locs
    @test apply_direction(wB1_loc, Direction.NE) in white_placement_locs
    @test apply_direction(wB1_loc, Direction.W) in white_placement_locs
    @test apply_direction(wB1_loc, Direction.SE) in white_placement_locs
    @test apply_direction(wB1_loc, Direction.SW) in white_placement_locs
    @test length(black_placement_locs) == 5
    @test apply_direction(bB1_loc, Direction.NW) in black_placement_locs
    @test apply_direction(bB1_loc, Direction.NE) in black_placement_locs
    @test apply_direction(bB1_loc, Direction.E) in black_placement_locs
    @test apply_direction(bB1_loc, Direction.SE) in black_placement_locs
    @test apply_direction(bB1_loc, Direction.SW) in black_placement_locs
end
