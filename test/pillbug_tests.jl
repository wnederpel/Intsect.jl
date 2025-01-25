@testitem "The Pillbug CANNOT move the piece the other player just moved." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [raw"wP", raw"bP wP-", raw"wQ \wP", raw"bQ bP\\", raw"wQ \bP"]

    for movestring in movestrings
        do_action(board, movestring)
    end
    valid_actions = validactions(board)
    @test_throws ErrorException action_from_move_string(board, "wQ bP/")
    @test action_from_move_string(board, "wP bP/") in valid_actions
end

@testitem "The Pillbug CANNOT move any piece in a stack of pieces." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [
        raw"wP",
        raw"bP wP-",
        raw"wQ \wP",
        raw"bQ bP\\",
        raw"wB1 /wP",
        raw"bB1 bQ-",
        raw"wB1 wP",
        raw"bM bB1-",
        raw"wQ \bP",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end
    valid_actions = validactions(board)

    @test_throws ErrorException action_from_move_string(board, "wB1 bP/")
    @test_throws ErrorException action_from_move_string(board, "wP bP/")
    @test action_from_move_string(board, "wQ bP/") in valid_actions
end

@testitem "The Pillbug CANNOT move a piece if it splits the hive (violating the One Hive Rule)." begin
    @test false
end

@testitem "The Pillbug CANNOT move a piece through a too-narrow gap of stacked pieces (violating the Freedom to Move Rule)." begin
    @test false
end

@testitem "Any piece just moved by the Pillbug CANNOT move OR be moved OR use its special ability on the next player’s turn." begin
    @test false
end

@testitem "A Pillbug that has used its ability has NOT been physically moved, therefore it CAN be physically moved by the opposing Pillbug on the next player’s turn." begin
    @test false
end

@testitem "The Mosquito can mimic either the movement OR special ability of the Pillbug, EVEN WHEN the Pillbug it is touching has been rendered immobile by the opposing Pillbug (as described above)." begin
    @test false
end

@testitem "A Pillbug under a Beetle (or Mosquito acting as a Beetle) CANNOT move OR use its ability, like any piece trapped under a stack." begin
    @test false
end