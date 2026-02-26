@testitem "SuggestedActions tracks added placement actions" begin
    board = handle_newgame_command(MLPGame)
    valid_indices = validactions_indices(board)
    @test !isempty(valid_indices)

    actions = Vector{Int32}(undef, length(valid_indices))
    sa = SuggestedActions(0, actions, HexSet(), HexSet())

    first_index = Int32(valid_indices[1])
    add!(sa, first_index)

    @test sa.index == 1
    @test in(first_index, sa)

    first_action = ALL_ACTIONS[Int(first_index)]
    @test sa.goal_loc_hs[first_action.goal_loc]
    @test sa.moving_loc_hs[0]

    if length(valid_indices) > 1
        second_index = Int32(valid_indices[2])
        @test !in(second_index, sa)
    end
end
