@testitem "The Pillbug CANNOT move the piece the other player just moved." begin
    board = handle_newgame_command(MLPGame)

    movestrings = [raw"wP", raw"bP wP-", raw"wQ \wP", raw"bQ bP\\", raw"wQ \bP"]

    for movestring in movestrings
        do_action(board, movestring)
    end
    valid_actions = validactions(board)
    @test_throws ErrorException action_from_move_string(board, raw"wQ bP/")
    @test action_from_move_string(board, raw"wP bP/") in valid_actions
end

@testitem "The Pillbug CANNOT move any piece in a stack of pieces." begin
    board = handle_newgame_command(MLPGame)

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

    show_valid_actions(board)

    @test_throws ErrorException action_from_move_string(board, raw"wB1 bP/")
    @test_throws ErrorException action_from_move_string(board, raw"wP bP/")
    # The wq just moved
    @test_throws ErrorException action_from_move_string(board, raw"wQ bP/")

    do_action(board, raw"bS1 bM-")
    do_action(board, raw"wM -wQ")

    valid_actions = validactions(board)

    @test action_from_move_string(board, raw"wQ bP/") in valid_actions
end

@testitem "The Pillbug CANNOT move a piece if it splits the hive  (violating the One Hive Rule)." begin
    board = handle_newgame_command(MLPGame)

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
        raw"bS1 bM-",
        raw"wM wQ/",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    @test_throws ErrorException action_from_move_string(board, raw"wQ bP/")
end

@testitem "The Pillbug CANNOT move a piece through a too-narrow gap of stacked pieces (violating the Freedom to Move Rule)." begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wP",
        raw"bP wP-",
        raw"wQ /wP",
        raw"bQ bP\\",
        raw"wM \wP",
        raw"bM /bQ",
        raw"wB1 \wQ",
        raw"bB1 bQ/",
        raw"wM \bP",
        raw"bM wP\\",
        raw"wB1 wP",
        raw"bB1 bP",
        raw"wB1 wM",
        raw"bB1 bM",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)

    @test action_from_move_string(board, raw"wQ \wP") in valid_actions
    @test filter(action -> action isa Move, valid_actions) |> length == 5
    @test filter(action -> action isa Climb, valid_actions) |> length == 6
    @test_throws ErrorException action_from_move_string(board, raw"bP -wP")
    @test_throws ErrorException action_from_move_string(board, raw"bP \wP")

    more_movestrings = [
        raw"wP -wB1",
        raw"bQ bB1\\",
        raw"wP \wB1",
        raw"bQ bB1-",
        raw"wP wB1/",
        raw"bQ bB1\\",
        raw"wP wB1-",
    ]

    for movestring in more_movestrings
        do_action(board, movestring)
    end

    @test_throws ErrorException action_from_move_string(board, raw"wP bP-")
    @test_throws ErrorException action_from_move_string(board, raw"wP -bP")

    do_action(board, raw"bQ /bB1")

    @test_throws ErrorException action_from_move_string(board, raw"bP wP/")

    do_action(board, raw"wQ -bQ")

    valid_actions = validactions(board)
    @test_throws ErrorException action_from_move_string(board, raw"wP -bP")
    @test action_from_move_string(board, raw"wP bP-") in valid_actions
    @test action_from_move_string(board, raw"wP bP\\") in valid_actions

    do_action(board, raw"bB1 -bB1")
    do_action(board, raw"wQ -bB1")

    valid_actions = validactions(board)
    @test action_from_move_string(board, raw"wP -bP") in valid_actions
    @test_throws ErrorException action_from_move_string(board, raw"wP /bP")
end

@testitem "Any piece just moved by the Pillbug CANNOT move OR be moved OR use its  special ability on the next player’s turn." begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wP",
        raw"bP wP-",
        raw"wQ /wP",
        raw"bQ bP\\",
        raw"wM \wP",
        raw"bM /bQ",
        raw"wB1 \wQ",
        raw"bB1 bQ/",
        raw"wM \bP",
        raw"bM wP\\",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)

    mosquito_throw_moves = [raw"bP -wM", raw"bP wM-", raw"bP wM/", raw"bP \wM"]
    for mosquito_throw_move in mosquito_throw_moves
        @test action_from_move_string(board, mosquito_throw_move) in valid_actions
    end

    do_action(board, raw"bP -wM")

    # bP cannot move itself
    @test_throws ErrorException action_from_move_string(board, raw"bP \wB")
    # bP cannot do special move
    @test_throws ErrorException action_from_move_string(board, raw"wB -wP")
end

@testitem "A Pillbug that has used its ability has NOT been physically moved,  therefore it CAN be physically moved by the opposing Pillbug on the next player’s turn." begin
    board = handle_newgame_command(MLPGame)

    movestrings = [raw"wP", raw"bP wP-", raw"wQ /wP", raw"bQ bP\\", raw"wQ wP\\", raw"bQ \bP"]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)

    @test action_from_move_string(board, raw"bP -wP") in valid_actions
end

@testitem "The Mosquito can mimic either the movement OR special ability of the Pillbug, EVEN WHEN the Pillbug it is touching has been rendered immobile by the one hive rule." begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wP",
        raw"bP wP-",
        raw"wQ /wP",
        raw"bQ bP\\",
        raw"wM \wP",
        raw"bM bP/",
        raw"wA1 \wQ",
        raw"bA1 bM\\",
        raw"wA1 -wQ",
        raw"bM wM/",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    valid_actions = validactions(board)
    @test filter(action -> action isa Move, valid_actions) |> length == 16

    do_action(board, raw"wA1 /wQ")
    do_action(board, raw"bA1 bQ-")

    valid_actions = validactions(board)

    mosquito_throw_moves = [raw"bM -wM", raw"bM wM-", raw"bM \wM", raw"bM /wM"]
    for mosquito_throw_move in mosquito_throw_moves
        @test action_from_move_string(board, mosquito_throw_move) in valid_actions
    end
end

@testitem "The Mosquito can mimic either the movement OR special ability of the Pillbug, EVEN WHEN the Pillbug it is touching has been rendered immobile by the opposing Pillbug (as described above)." begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wP",
        raw"bB1 wP-",
        raw"wQ /wP",
        raw"bP bB1\\",
        raw"wL /wQ",
        raw"bQ bP/",
        raw"wG1 /wL",
        raw"bP wP\\",
        raw"wG2 /wG1",
        raw"bM \bQ",
        raw"bP \bB1",
        raw"bB1 bQ/",
    ]

    for movestring in movestrings
        @test action_from_move_string(board, movestring) in validactions(board)
        do_action(board, movestring)
    end

    valid_actions = validactions(board)
end

@testitem "A Pillbug under a Beetle (or Mosquito acting as a Beetle) CANNOT move OR use its ability, like any piece trapped under a stack." begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wP",
        raw"bP wP-",
        raw"wQ /wP",
        raw"bQ bP\\",
        raw"wM \wQ",
        raw"bB1 bQ/",
        raw"wB1 \wP",
        raw"bB1 bP",
        raw"wM wP",
        raw"bQ wM\\",
        raw"wB1 \wQ",
    ]

    for movestring in movestrings
        do_action(board, movestring)
    end

    @test_throws ErrorException action_from_move_string(board, raw"bQ bB1-")

    do_action(board, raw"bA1 bB1-")

    @test_throws ErrorException action_from_move_string(board, raw"wQ bM/")
    @test_throws ErrorException action_from_move_string(board, raw"bQ bM/")
end

@testitem "mosquito can throw pillbug" begin
    board = handle_newgame_command(MLPGame)

    movestrings = [
        raw"wM",
        raw"bP \wM",
        raw"wS1 /wM",
        raw"bB1 bP/",
        raw"wB1 -wS1",
        raw"bM \bB1",
        raw"wQ wM\\",
        raw"bQ /bM",
        raw"wG1 /wB1",
        raw"bG1 -bM",
        raw"wP -wG1",
        raw"bM bB1",
        raw"wQ /bP",
        raw"bG2 bG1/",
        raw"wP wP\\",
        raw"bB2 -bG1",
        raw"wB2 wB1\\",
        raw"wQ bM\\",
        raw"wA1 -wB1",
        raw"bA1 bM/",
        raw"bP wM-",
    ]

    for movestring in movestrings
        show(board)
        do_action(board, movestring)
    end
    undo(board)
    do_action(board, raw"wQ wM\\")
    @test true
end