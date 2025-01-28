@testitem "Add test items, check for moving throught gates etc. on top of the hive. See screen shot for example" begin
    board = handle_newgame_command(Gametype.MLP)

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

    @test_throws ErrorException action_from_move_string(board, "wL bM-")
    @test_throws ErrorException action_from_move_string(board, "wL bM\\")
    @test_throws ErrorException action_from_move_string(board, "wL /bM")
    @test_throws ErrorException action_from_move_string(board, "wL bB1/")
    @test_throws ErrorException action_from_move_string(board, "wL bB1-")
    @test_throws ErrorException action_from_move_string(board, "wL \bB1")
    @test_throws ErrorException action_from_move_string(board, "wL -bB1")
    @test action_from_move_string(board, "wL bM/") in valid_actions
    @test action_from_move_string(board, "wL -wQ") in valid_actions
    @test action_from_move_string(board, "wL wQ/") in valid_actions
    @test action_from_move_string(board, "wL wQ\\") in valid_actions
    @test action_from_move_string(board, "wL wB1\\") in valid_actions
    @test action_from_move_string(board, "wL bG1-") in valid_actions
    show(board)
end

@testitem "Mosquito can ONLY do beetle moves while on top" begin end