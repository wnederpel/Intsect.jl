@testitem "The Pillbug CANNOT move the piece the other player just moved." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = ["wP", "bP wP-", "wQ \wP", "bQ bP\\", "wQ \bP"]

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
        "wP", "bP wP-", "wQ \wP", "bQ bP\\", "wB1 /wP", "bB1 bQ-", "wB1 wP", "bM bB1-", "wQ \bP"
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    show_valid_actions(board)

    @test_throws ErrorException action_from_move_string(board, "wB1 bP/")
    @test_throws ErrorException action_from_move_string(board, "wP bP/")
    # The wq just moved
    @test_throws ErrorException action_from_move_string(board, "wQ bP/")

    do_action(board, "bS1 bM-")
    do_action(board, "wM -wQ")

    valid_actions = validactions(board)

    @test action_from_move_string(board, "wQ bP/") in valid_actions
end

@testitem "The Pillbug CANNOT move a piece if it splits the hive  (violating the One Hive Rule)." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [
        "wP",
        "bP wP-",
        "wQ \wP",
        "bQ bP\\",
        "wB1 /wP",
        "bB1 bQ-",
        "wB1 wP",
        "bM bB1-",
        "wQ \bP",
        "bS1 bM-",
        "wM wQ/",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    @test_throws ErrorException action_from_move_string(board, "wQ bP/")
end

@testitem "The Pillbug CANNOT move a piece through a too-narrow gap of stacked pieces (violating the Freedom to Move Rule)." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [
        "wP",
        "bP wP-",
        "wQ /wP",
        "bQ bP\\",
        "wM \wP",
        "bM /bQ",
        "wB1 \wQ",
        "bB1 bQ/",
        "wM \bP",
        "bM wP\\",
        "wB1 wP",
        "bB1 bP",
        "wB1 wM",
        "bB1 bM",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)

    @test action_from_move_string(board, "wQ \wP") in valid_actions
    @test filter(action -> action isa Move, valid_actions) |> length == 5
    @test filter(action -> action isa Climb, valid_actions) |> length == 6
    @test_throws ErrorException action_from_move_string(board, "bP -wP")
    @test_throws ErrorException action_from_move_string(board, "bP \wP")

    more_movestrings = [
        "wP -wB1", "bQ bB1\\", "wP \wB1", "bQ bB1-", "wP wB1/", "bQ bB1\\", "wP wB1-"
    ]

    for movestring in more_movestrings
        do_action(board, movestring)
    end

    @test_throws ErrorException action_from_move_string(board, "wP bP-")
    @test_throws ErrorException action_from_move_string(board, "wP -bP")

    do_action(board, "bQ /bB1")

    @test_throws ErrorException action_from_move_string(board, "bP wP/")

    do_action(board, "wQ -bQ")

    valid_actions = validactions(board)
    @test_throws ErrorException action_from_move_string(board, "wP -bP")
    @test action_from_move_string(board, "wP bP-") in valid_actions
    @test action_from_move_string(board, "wP bP\\") in valid_actions

    do_action(board, "bB1 -bB1")
    do_action(board, "wQ -bB1")

    valid_actions = validactions(board)
    @test action_from_move_string(board, "wP -bP") in valid_actions
    @test_throws ErrorException action_from_move_string(board, "wP /bP")
end

@testitem "Any piece just moved by the Pillbug CANNOT move OR be moved OR use its  special ability on the next player’s turn." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [
        "wP",
        "bP wP-",
        "wQ /wP",
        "bQ bP\\",
        "wM \wP",
        "bM /bQ",
        "wB1 \wQ",
        "bB1 bQ/",
        "wM \bP",
        "bM wP\\",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)

    mosquito_throw_moves = ["bP -wM", "bP wM-", "bP wM/", "bP \wM"]
    for mosquito_throw_move in mosquito_throw_moves
        @test action_from_move_string(board, mosquito_throw_move) in valid_actions
    end

    do_action(board, "bP -wM")

    # bP cannot move itself
    @test_throws ErrorException action_from_move_string(board, "bP \wB")
    # bP cannot do special move
    @test_throws ErrorException action_from_move_string(board, "wB -wP")
end

@testitem "A Pillbug that has used its ability has NOT been physically moved,  therefore it CAN be physically moved by the opposing Pillbug on the next player’s turn." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = ["wP", "bP wP-", "wQ /wP", "bQ bP\\", "wQ wP\\", "bQ \bP"]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)

    @test action_from_move_string(board, "bP -wP") in valid_actions
end

@testitem "The Mosquito can mimic either the movement OR special ability of the Pillbug, EVEN WHEN the Pillbug it is touching has been rendered immobile by the one hive rule." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [
        "wP",
        "bP wP-",
        "wQ /wP",
        "bQ bP\\",
        "wM \wP",
        "bM bP/",
        "wA1 \wQ",
        "bA1 bM\\",
        "wA1 -wQ",
        "bM wM/",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)
    @test filter(action -> action isa Move, valid_actions) |> length == 16

    do_action(board, "wA1 /wQ")
    do_action(board, "bA1 bQ-")

    valid_actions = validactions(board)

    mosquito_throw_moves = ["bM -wM", "bM wM-", "bM \wM", "bM /wM"]
    for mosquito_throw_move in mosquito_throw_moves
        @test action_from_move_string(board, mosquito_throw_move) in valid_actions
    end
end

@testitem "The Mosquito can mimic either the movement OR special ability of the Pillbug, EVEN WHEN the Pillbug it is touching has been rendered immobile by the opposing Pillbug (as described above)." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [
        "wP",
        "bB1 wP-",
        "wQ /wP",
        "bP bB1\\",
        "wL /wQ",
        "bQ bP/",
        "wG1 /wL",
        "bP wP\\",
        "wG2 /wG1",
        "bM \bQ",
        "bP \bB1",
        "bB1 bQ/",
    ]

    for movestring in movestrings
        @test action_from_move_string(board, movestring) in validactions(board)
        do_action(board, movestring)
    end

    valid_actions = validactions(board)
end

@testitem "A Pillbug under a Beetle (or Mosquito acting as a Beetle) CANNOT move OR use its ability, like any piece trapped under a stack." begin
    board = handle_newgame_command(Gametype.MLP)

    movestrings = [
        "wP",
        "bP wP-",
        "wQ /wP",
        "bQ bP\\",
        "wM \wQ",
        "bB1 bQ/",
        "wB1 \wP",
        "bB1 bP",
        "wM wP",
        "bQ wM\\",
        "wB1 \wQ",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    @test_throws ErrorException action_from_move_string(board, "bQ bB1-")

    do_action(board, "bA1 bB1-")

    @test_throws ErrorException action_from_move_string(board, "wQ bM/")
    @test_throws ErrorException action_from_move_string(board, "bQ bM/")
end