@testitem "Correctly update pillbug specials moves do and undo bb update" begin
    board = handle_newgame_command(MLPGame)
    actions = [
        Placement(136, get_tile_from_string("wA1")),
        Placement(120, get_tile_from_string("bP")),
        Placement(135, get_tile_from_string("wQ")),
        Placement(103, get_tile_from_string("bQ")),
        Move(135, 119),
        Move(136, 104),
    ]

    for action in actions
        do_action(board, action)
    end

    @test count_ones(board.white_pieces) == 2
    @test count_ones(board.black_pieces) == 2

    undo(board)

    @test count_ones(board.white_pieces) == 2
    @test count_ones(board.black_pieces) == 2
end

@testitem "undo pillbug special is the same as do climb" begin
    board = handle_newgame_command(MLPGame)

    actions = [
        Placement(136, 0x04),
        Placement(120, 0x38),
        Placement(135, 0x24),
        Placement(103, 0x20),
        Move(135, 119),
        Move(136, 104),
    ]

    do_bbs = []

    for action in actions
        push!(do_bbs, (copy(board.white_pieces), copy(board.black_pieces)))
        do_action(board, action)
    end

    for i in reverse(eachindex(do_bbs))
        undo(board)

        @test board.white_pieces == do_bbs[i][1]
        @test board.black_pieces == do_bbs[i][2]
    end
end

@testitem "Correctly update climb do and undo bb updates" begin
    board = handle_newgame_command(MLPGame)

    actions = [
        Placement(136, 0x14),
        Placement(120, 0x10),
        Placement(135, 0x24),
        Placement(103, 0x20),
        Move(135, 119),
        Climb(120, 103),
        Climb(136, 119),
        Climb(103, 119),
    ]

    for action in actions[begin:(begin + 4)]
        do_action(board, action)
    end

    @test count_ones(board.white_pieces) == 2
    @test count_ones(board.black_pieces) == 2

    do_action(board, actions[begin + 5])

    @test count_ones(board.white_pieces) == 2
    @test count_ones(board.black_pieces) == 1

    do_action(board, actions[begin + 6])

    @test count_ones(board.white_pieces) == 1
    @test count_ones(board.black_pieces) == 1

    do_action(board, actions[begin + 7])

    @test count_ones(board.white_pieces) == 0
    @test count_ones(board.black_pieces) == 2
end

@testitem "undo climb is the same as do climb" begin
    board = handle_newgame_command(MLPGame)

    actions = [
        Placement(136, 0x14),
        Placement(120, 0x10),
        Placement(135, 0x24),
        Placement(103, 0x20),
        Move(135, 119),
        Climb(120, 103),
        Climb(136, 119),
        Climb(103, 119),
    ]

    do_bbs = []

    for action in actions
        push!(do_bbs, (copy(board.white_pieces), copy(board.black_pieces)))
        do_action(board, action)
    end

    for i in reverse(eachindex(do_bbs))
        undo(board)

        @test board.white_pieces == do_bbs[i][1]
        @test board.black_pieces == do_bbs[i][2]
    end
end