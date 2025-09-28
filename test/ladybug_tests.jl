@testitem "Add test items, check for moving throught gates etc. on top of the hive. See screen shot for example" begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wG1",
        raw"bG1 wG1-",
        raw"wB1 /wG1",
        raw"bB1 bG1-",
        raw"wQ \wB1",
        raw"bQ \bB1",
        raw"wL \wG1",
        raw"bB1 bQ",
        raw"wB1 wG1",
        raw"bM bB1\\",
        raw"wL \bG1",
        raw"bM bG1\\",
    ]

    for movestring in movestrings
        @test action_from_move_string(board, movestring) in validactions(board)
        do_action(board, movestring)
    end
    valid_actions = validactions(board)

    @test_throws ErrorException action_from_move_string(board, raw"wL bM-")
    @test_throws ErrorException action_from_move_string(board, raw"wL bM\\")
    @test_throws ErrorException action_from_move_string(board, raw"wL /bM")
    @test_throws ErrorException action_from_move_string(board, raw"wL bB1/")
    @test_throws ErrorException action_from_move_string(board, raw"wL bB1-")
    @test_throws ErrorException action_from_move_string(board, raw"wL \bB1")
    @test_throws ErrorException action_from_move_string(board, raw"wL -bB1")
    @test action_from_move_string(board, raw"wL bM/") in valid_actions
    @test action_from_move_string(board, raw"wL -wQ") in valid_actions
    @test action_from_move_string(board, raw"wL wQ/") in valid_actions
    @test action_from_move_string(board, raw"wL wQ\\") in valid_actions
    @test action_from_move_string(board, raw"wL wB1\\") in valid_actions
    @test action_from_move_string(board, raw"wL bG1-") in valid_actions
end

@testitem "Mosquito can ONLY do beetle moves while on top" begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wB1",
        raw"bA1 wB1-",
        raw"wQ /wB1",
        raw"bQ bA1\\",
        raw"wM \wQ",
        raw"bL bA1/",
        raw"wM wB1",
        raw"bL -wM",
    ]

    for movestring in movestrings
        @test action_from_move_string(board, movestring) in validactions(board)
        do_action(board, movestring)
    end
    valid_actions = validactions(board)

    @test_throws ErrorException action_from_move_string(board, raw"wM bA1-")
    @test_throws ErrorException action_from_move_string(board, raw"wM bQ")
    @test action_from_move_string(board, raw"wM wM-") in valid_actions
    @test action_from_move_string(board, raw"wM wM\\") in valid_actions
    @test action_from_move_string(board, raw"wM wM/") in valid_actions
    @test action_from_move_string(board, raw"wM /wM") in valid_actions
    @test action_from_move_string(board, raw"wM -wM") in valid_actions
    @test action_from_move_string(board, raw"wM \wM") in valid_actions
end

@testitem "Game can handle moves by multiples of the same piece" begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wB1",
        raw"bB1 wB1-",
        raw"wQ -wB1",
        raw"bQ bB1-",
        raw"wB2 \wB1",
        raw"bB2 bB1/",
        raw"wB2 wB1",
        raw"bB2 bB1",
    ]

    for movestring in movestrings
        @test action_from_move_string(board, movestring) in validactions(board)
        do_action(board, movestring)
    end
end

@testitem "the above with a new piece" begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wB1",
        raw"bB1 wB1-",
        raw"wQ -wB1",
        raw"bQ bB1-",
        raw"wM \wB1",
        raw"bM bB1/",
        raw"wM wB1",
        raw"bM bB1",
    ]

    for movestring in movestrings
        valid_actions = validactions(board)
        @test action_from_move_string(board, movestring) in valid_actions
        do_action(board, movestring)
    end
end

@testitem "What happens when a mosquito is on top and only touches another mosquito?" begin
    @test false
end