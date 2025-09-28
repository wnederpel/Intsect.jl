function add_action(
    board::Board, action::Action, move_buffer; avoid_duplicates=false, start_search=1
)
    # Do no use show(action) here because tiles might be Temporarily deleted -> string generation does not work
    if avoid_duplicates
        if move_not_duplicate(board, action, move_buffer, start_search)
            add_action!(board, action, move_buffer)
        end
    else
        add_action!(board, action, move_buffer)
    end
end

function add_action(board::Board, placement::Placement, move_buffer)
    add_action!(board, placement, move_buffer)
    return nothing
end

function add_action!(board::Board, action::Action, move_buffer)
    # TODO eff: do not use struct action index, but pass it around
    @inbounds move_buffer[board.action_index] = action_index(action)
    board.action_index += 1
    return nothing
end

function validactions_indices(board)
    @no_escape begin
        move_buffer = @alloc(Int, VALID_BUFFER_SIZE)
        validactions!(board, move_buffer)
        valid_actions = extract_valid_actions_index(board, move_buffer)
    end
    return valid_actions
end

function validactions(board)
    return ALL_ACTIONS[validactions_indices(board)]
end

function extract_valid_actions_index(board, move_buffer)
    tmp = board.action_index
    board.action_index = 1
    return copy(move_buffer[1:(tmp - 1)])
end

function extract_valid_actions(board, move_buffer=nothing)
    if move_buffer === nothing
        move_buffer = board.validactions
    end
    tmp = board.action_index
    board.action_index = 1
    return ALL_ACTIONS[move_buffer[1:(tmp - 1)]]
end

function validactions!(board::Board, move_buffer)
    board.action_index = 1
    if board.gameover
        return nothing
    end

    need_to_place_queen = !board.queen_placed[board.current_color + 1] && board.turn == 4
    first_placement = board.ply == 1
    second_placement = board.ply == 2

    if need_to_place_queen
        queenplacements(board, move_buffer)
    elseif first_placement
        firstplacements(board, move_buffer)
    elseif second_placement
        secondplacements(board, move_buffer)
    else
        validactions_general(board, move_buffer)
    end

    return nothing
end

"""
Valid actions for the default case
"""
function validactions_general(board::Board, move_buffer)
    add_placements(board, move_buffer)
    num_placements = board.action_index - 1

    if board.queen_placed[board.current_color + 1]
        if board.general_pinned_update_required
            update_ispinned_general!(board)
            board.general_pinned_update_required = false
        end
        add_moves(board, board.ispinned, move_buffer, num_placements)
    end

    if board.action_index == 1
        show(board; simple=false)
        show(board.white_pieces)
        show(board.black_pieces)
        add_action(board, Pass(), move_buffer)
    end

    return nothing
end

function add_placements(board, move_buffer)
    placement_locs_bb = BitBoard(0, 0)
    fill_placement_locs_bb!(placement_locs_bb, board)

    prev_loc = -1

    while true
        loc = get_and_remove_first_loc!(placement_locs_bb)
        prev_loc = loc
        if loc == INVALID_LOC
            break
        end
        for tile in board.placeable_tiles[board.current_color + 1]
            if tile != EMPTY_TILE
                add_action(board, Placement(loc, tile), move_buffer)
            end
        end
    end
    return nothing
end

function add_moves(board, ispinned, move_buffer, num_placements)
    color_odd = board.current_color + 0x01
    actions_before_throw_moves = num_placements
    for bug in 0x01:0x08
        if get_tile_bug_num(board.placeable_tiles[color_odd][bug]) == 0
            continue
        end
        for num in 0x00:MAX_NUMS[bug]
            semi_tile = tile_from_info_as_index_odd(color_odd, bug, num)
            @inbounds loc = board.tile_locs[semi_tile]

            if loc == NOT_PLACED
                break
            end
            if loc == UNDERGROUND || loc == board.just_moved_loc || loc == INVALID_LOC
                continue
            end
            # Generate moves for placed tiles
            tile = get_tile_on_board(board, loc)
            actions_before_throw_moves = bugmoves(
                board,
                loc,
                bug,
                get_tile_height_unsafe(tile),
                ispinned,
                move_buffer,
                num_placements;
                actions_before_throw_moves,
            )
        end
    end
end

"""
valid actions for when the queen must be placed
"""
function queenplacements(board, move_buffer)
    queen_tile =
        board.current_color == WHITE ? get_tile_from_string(board, "wQ") :
        get_tile_from_string(board, "bQ")

    placement_locs_bb = BitBoard(0, 0)
    fill_placement_locs_bb!(placement_locs_bb, board)

    prev_loc = -1
    while true
        loc = get_and_remove_first_loc!(placement_locs_bb)
        prev_loc = loc
        if loc == INVALID_LOC
            break
        end
        add_action(board, Placement(loc, queen_tile), move_buffer)
    end
    return nothing

    return nothing
end

"""
valid actions for when the first move is made
"""
function firstplacements(board, move_buffer)
    for tile in board.placeable_tiles[board.current_color + 1]
        if tile != EMPTY_TILE && get_tile_bug(tile) != Integer(Bug.QUEEN)
            add_action(board, Placement(MID, tile), move_buffer)
        end
    end
    return nothing
end

"""
valid actions for second placement (first placement by black)
"""
function secondplacements(board, move_buffer)
    for loc in allneighs(MID)
        for tile in board.placeable_tiles[board.current_color + 1]
            if tile != EMPTY_TILE && get_tile_bug(tile) != Integer(Bug.QUEEN)
                add_action(board, Placement(loc, tile), move_buffer)
            end
        end
    end
    return nothing
end

@inline function bugmoves(
    board,
    loc,
    bug,
    height,
    ispinned,
    move_buffer,
    num_placements;
    avoid_duplicates=false,
    start_search=board.action_index,
    actions_before_throw_moves=num_placements,
)
    # Pill bug can yield special moves, even when pinned
    # Moquito can yield pill bug moves, even when pinned
    # Beetle can move on top op hive, even when pinned
    if bug == Integer(Bug.PILLBUG)
        actions_before_throw_moves = pillbugmoves(
            board, loc, ispinned, move_buffer; num_placements, avoid_duplicates, start_search
        )
    elseif bug == Integer(Bug.MOSQUITO)
        mosquitomoves(
            board, loc, height, ispinned, move_buffer, num_placements, actions_before_throw_moves
        )
    elseif bug == Integer(Bug.BEETLE) && (!ispinned[loc + 1] || height != 1)
        beetlemoves(board, loc, height, move_buffer; avoid_duplicates, start_search)
    elseif !ispinned[loc + 1]
        if bug == Integer(Bug.ANT)
            antmoves(board, loc, move_buffer; avoid_duplicates, start_search)
        elseif bug == Integer(Bug.SPIDER)
            spidermoves(board, loc, move_buffer; start_search)
        elseif bug == Integer(Bug.QUEEN)
            queenmoves(board, loc, move_buffer; avoid_duplicates, start_search)
        elseif bug == Integer(Bug.GRASSHOPPER)
            grasshoppermoves(board, loc, move_buffer; avoid_duplicates, start_search)
        elseif bug == Integer(Bug.LADYBUG)
            ladybugmoves(board, loc, move_buffer; start_search)
        end
    end
    return actions_before_throw_moves
end

function mosquitomoves(
    board, loc, height, ispinned, move_buffer, num_placements, actions_before_throw_moves
)
    if height > 1
        beetlemoves(board, loc, height, move_buffer)
        return nothing
    end
    num_actions_before_mosquito = board.action_index
    for neigh in allneighs(loc)
        tile = get_tile_on_board(board, neigh)

        if tile != EMPTY_TILE
            bug = get_tile_bug(tile)
            if bug != Integer(Bug.MOSQUITO)
                # Needs to avoid duplicates bc multiple of the same bugs can touch the mosquito (and the same move can come for different bugs)
                # Set the number of actions before the mosquito as the start since this mosquito moveset consist of multiple bugmoves.
                bugmoves(
                    board,
                    loc,
                    bug,
                    height,
                    ispinned,
                    move_buffer,
                    num_placements;
                    avoid_duplicates=true,
                    start_search=actions_before_throw_moves,
                )
            end
        end
    end

    return nothing
end

function pillbugmoves(
    board,
    startloc,
    ispinned,
    move_buffer;
    num_placements=0,
    avoid_duplicates=false,
    start_search=board.action_index,
)
    maxdepth = 1
    if !ispinned[startloc + 1]
        # pillbug moves before mosquito, so we do not have to remove duplicates
        moves_to_depth(
            board, startloc, maxdepth, move_buffer; avoid_duplicates=avoid_duplicates, start_search
        )
    end
    # Save this because the mosquito moves had to avoid duplicate throw moves
    actions_before_throw_moves = board.action_index
    # pillbug also has special moves
    # For all surrounding tiles, if they are not pinned, and did not just move,
    # and can slide on the pillbug, and the tile is not stacked
    # they can be slid on top of the pillbug, and then slid off
    neighlocs = allneighs(startloc)
    # For each neigh, see if it can slide high
    @no_escape begin
        slidelocs = @alloc(Int, 6)
        j = 1
        for i in 1:6
            if canslidepillbug(i, board, neighlocs)
                slidelocs[j] = neighlocs[i]
                j += 1
            end
        end

        for i in 1:6
            loc = neighlocs[i]
            tile = get_tile_on_board(board, loc)
            if tile != EMPTY_TILE &&
                !ispinned[loc + 1] &&
                loc != board.just_moved_loc &&
                get_tile_height(tile) == 1 &&
                canslidepillbug(i, board, neighlocs)
                for slideloc in slidelocs
                    if slideloc != loc && get_tile_on_board(board, slideloc) == EMPTY_TILE
                        move = Move(loc, slideloc)
                        # Throwing moves move other pieces, this can always make duplicate moves for any bug
                        add_action(
                            board,
                            move,
                            move_buffer;
                            avoid_duplicates=true,
                            start_search=num_placements + 1,
                        )
                    end
                end
            end
        end
    end

    return actions_before_throw_moves
end

function ladybugmoves(board, startloc, move_buffer; start_search=board.action_index)
    maxdepth = 3
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves_to_depth_ladybug!(board, startloc, maxdepth, move_buffer, start_search)

    set_tile_on_board(board, startloc, tmp_tile)

    return nothing
end

function moves_to_depth_ladybug!(
    board, startloc, depth, move_buffer, start_search; cur_loc=startloc
)
    if depth == 0
        if cur_loc != startloc
            add_action(
                board, Move(startloc, cur_loc), move_buffer; avoid_duplicates=true, start_search
            )
        end
        return nothing
    end
    neighlocs = allneighs(cur_loc)
    for i in 1:6
        height = get_tile_height(get_tile_on_board(board, cur_loc))
        if (
                depth == 3 &&
                get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                canslidehigh(i, board, neighlocs, 1)
            ) ||
            (
                depth == 2 &&
                get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                canslidehigh(i, board, neighlocs, height + 1)
            ) ||
            (
                depth == 1 &&
                get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE &&
                canslidehigh(i, board, neighlocs, height + 1)
            )
            moves_to_depth_ladybug!(
                board, startloc, depth - 1, move_buffer, start_search; cur_loc=neighlocs[i]
            )
        end
    end

    return nothing
end

function grasshoppermoves(
    board, startloc, move_buffer; avoid_duplicates=false, start_search=board.action_index
)
    for dir in instances(Direction.T)
        if get_tile_on_board(board, apply_direction(startloc, dir)) != EMPTY_TILE
            loc = startloc
            while true
                loc = apply_direction(loc, dir)
                tile = get_tile_on_board(board, loc)
                if tile == EMPTY_TILE
                    break
                end
            end
            add_action(board, Move(startloc, loc), move_buffer; avoid_duplicates, start_search)
        end
    end
    return nothing
end

function beetlemoves(
    board, startloc, height, move_buffer; avoid_duplicates=false, start_search=board.action_index
)
    neighlocs = allneighs(startloc)
    if height != 1
        # Can go anywhere, so long as it can slide with height
        for i in 1:6
            if canslidehigh(i, board, neighlocs, height)
                add_action(
                    board,
                    Climb(startloc, neighlocs[i]),
                    move_buffer;
                    avoid_duplicates,
                    start_search,
                )
            end
        end
        return nothing
    end
    # can go anywhere on top, or where it can slide
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    for i in 1:6
        if get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
            canslidehigh(i, board, neighlocs, 1)
            add_action(
                board, Climb(startloc, neighlocs[i]), move_buffer; avoid_duplicates, start_search
            )
        elseif get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE && canslide(i, board, neighlocs)
            add_action(
                board, Move(startloc, neighlocs[i]), move_buffer; avoid_duplicates, start_search
            )
        end
    end

    set_tile_on_board(board, startloc, tmp_tile)
    return nothing
end

@inline function canslidepillbug(i, board, neighlocs)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])

    return get_tile_height(neighleft) < 2 || get_tile_height(neighright) < 2
end

@inline function canslidehigh(i, board, neighlocs, height)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])
    goalheight = get_tile_height(get_tile_on_board(board, neighlocs[i]))

    return get_tile_height(neighleft) < max(goalheight + 1, height) ||
           get_tile_height(neighright) < max(goalheight + 1, height)
end

@inline function queenmoves(
    board, startloc, move_buffer; avoid_duplicates=false, start_search=board.action_as_index
)
    maxdepth = 1
    moves_to_depth(board, startloc, maxdepth, move_buffer; avoid_duplicates, start_search)
    return nothing
end

function spidermoves(board, startloc, move_buffer; start_search=board.action_index)
    maxdepth = 3
    moves_to_depth(board, startloc, maxdepth, move_buffer; avoid_duplicates=true, start_search)
    return nothing
end

function antmoves(board, startloc, move_buffer; avoid_duplicates=false, start_search)
    # todo speed: bitboards might be able to help here?
    tmp_tile = get_tile_on_board(board, startloc)
    # Temporarily remove the tile to find where it can move to
    set_tile_on_board(board, startloc, EMPTY_TILE)
    @no_escape begin
        discovered_dict = @alloc(eltype(false), GRID_SIZE)
        discovered_dict .= false

        stack_arr = @alloc(Int, GRID_SIZE)
        stack_ptr = 1

        # push
        stack_arr[stack_ptr] = startloc
        stack_ptr += 1

        while stack_ptr != 1
            # pop
            loc = stack_arr[stack_ptr - 1]
            stack_ptr -= 1

            stack_ptr = push_slidelocs!(board, stack_arr, stack_ptr, loc, discovered_dict)
        end
        set_tile_on_board(board, startloc, tmp_tile)

        for entry in eachindex(discovered_dict)
            goalloc = entry - 1
            if discovered_dict[entry] && goalloc != startloc
                add_action(
                    board, Move(startloc, goalloc), move_buffer; avoid_duplicates, start_search
                )
            end
        end
    end
    return nothing
end

function push_slidelocs!(board::Board, stack_arr, stack_ptr, loc, discovered_dict)
    neighlocs = allneighs(loc)
    for i in 1:6
        if canslide(i, board, neighlocs)
            if @inbounds !discovered_dict[neighlocs[i] + 1]
                # push
                @inbounds stack_arr[stack_ptr] = neighlocs[i]
                stack_ptr += 1

                @inbounds discovered_dict[neighlocs[i] + 1] = true
            end
        end
    end
    return stack_ptr
end

@inline function moves_to_depth(
    board, startloc, maxdepth, move_buffer; avoid_duplicates=false, start_search=board.action_index
)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves_to_depth!(board, startloc, maxdepth, move_buffer; avoid_duplicates, start_search)

    set_tile_on_board(board, startloc, tmp_tile)
    return nothing
end

@inline function moves_to_depth!(
    board,
    startloc,
    depth,
    move_buffer,
    cur_loc=startloc,
    prev_loc=nothing;
    avoid_duplicates=false,
    start_search,
)
    if depth == 0
        if cur_loc != startloc
            add_action(board, Move(startloc, cur_loc), move_buffer; avoid_duplicates, start_search)
        end
        return nothing
    end
    neighlocs = allneighs(cur_loc)
    for i in 1:6
        if canslide(i, board, neighlocs) && neighlocs[i] != prev_loc
            moves_to_depth!(
                board,
                startloc,
                depth - 1,
                move_buffer,
                neighlocs[i],
                cur_loc;
                avoid_duplicates,
                start_search,
            )
        end
    end
end

"""
From the current position, one can travel in a direcion when:

 1. the direction itself is not filled
 2. one of the two neighbouring directions is filled
"""
@inline function canslide(i, board, neighlocs)
    left_neigh = neighlocs[i == 1 ? 6 : i - 1]
    right_neigh = neighlocs[i == 6 ? 1 : i + 1]
    return get_tile_on_board(board, @inbounds neighlocs[i]) == EMPTY_TILE && (
        (@inbounds get_tile_on_board(board, left_neigh) == EMPTY_TILE) ⊻
        (@inbounds get_tile_on_board(board, right_neigh) == EMPTY_TILE)
    )
end

@inline function get_pinned_tiles!(board, last_goal_loc, last_moving_loc; inverse=false)
    # NOTE! the goal and moving loc have already happened!
    is_simple_goal, goal_neigh = is_simple_last_goal_loc(board, last_goal_loc, inverse)
    is_simple_moving, moving_neigh = is_simple_last_moving_loc(
        board, last_moving_loc, last_goal_loc
    )
    if is_simple_goal && is_simple_moving
        return update_ispinned_simple!(
            board, last_goal_loc, goal_neigh, last_moving_loc, moving_neigh
        )
        # TODO speed: implement the commented code
        # elseif is_last_change_elbow(board)
        #     update_ispinned_elbow!(board)
        #     return nothing
    end
    board.general_pinned_update_required = true
end

@inline function is_simple_last_goal_loc(board, last_goal_loc, inverse)
    # if the update comes from an inverse update, the last_goal_loc might be invalid (i.e. removal from moving loc, inverse placement, no relevant goal loc)
    if inverse && last_goal_loc < 0
        return true, INVALID_LOC
    end
    # there now is a tile at goal loc, if it has one neighbor is has created no cycles and a simple update can be done
    one_neigh, that_neigh = has_one_neigh_and_get(board, last_goal_loc)
    return one_neigh, that_neigh
end

@inline function is_simple_last_moving_loc(board, last_moving_loc, last_goal_loc)
    if last_moving_loc < 0
        return true, INVALID_LOC
    end
    # So a tile has moved avoid from last_moving_loc

    # If it is not emtpy rn (tile was on top), nothing changes at the moving loc, return true, invalid_loc as if it was a placement
    if get_tile_on_board(board, last_moving_loc) != EMPTY_TILE
        return true, INVALID_LOC
    end

    # If it is now empty and it had one neigh and that neigh is now free
    # make sure to avoid the last_goal_loc in the neigh check as that is the tile that just moved away from the movingloc
    # only avoid the last_goal_loc if it is not on top of some other tile and it exists
    skip_loc = INVALID_LOC
    if last_goal_loc >= 0 && get_tile_height_unsafe(get_tile_on_board(board, last_goal_loc)) == 0x01
        skip_loc = last_goal_loc
    end
    one_neigh, that_neigh = has_one_neigh_and_get(board, last_moving_loc; skip_loc=skip_loc)
    return one_neigh && has_one_neigh(board, that_neigh), that_neigh
end

@inline function has_one_neigh_and_get(board, loc; skip_loc=INVALID_LOC)
    # TODO: DO WITH BIT BOARD? -> still have to find the actual neigh somehow
    neigh_bb = get_neigh_bb(loc)
    filled_neighs = neigh_bb & (board.white_pieces | board.black_pieces)
    if skip_loc != INVALID_LOC
        skip_bb = get_bb(skip_loc)
        filled_neighs &= ~skip_bb
    end
    return count_ones(filled_neighs) == 1, get_first_loc(filled_neighs)
end

@inline function has_one_neigh(board, loc)
    neigh_bb = get_neigh_bb(loc)
    filled_neighs = neigh_bb & (board.white_pieces | board.black_pieces)
    return count_ones(filled_neighs) == 1
end

@inline function update_ispinned_simple!(
    board, last_goal_loc, goal_neigh, last_moving_loc, moving_neigh
)
    if moving_neigh >= 0
        @inbounds board.ispinned[moving_neigh + 1] = false
    end

    # If the goal_loc exists,
    # Then, at the goal loc, the neigh becomes stuck and you are unstuck
    if last_goal_loc >= 0
        @inbounds board.ispinned[last_goal_loc + 1] = false
        @inbounds board.ispinned[goal_neigh + 1] = true
    end

    return nothing
end

@inline function get_last_changed_locs(board)
    @inbounds last_action_index = board.history[board.last_history_index]
    return do_for_action(last_action_index, last_action -> get_last_changed_locs(last_action))
end

@inline function get_last_changed_locs(last_action::Placement)
    return last_action.goal_loc, INVALID_LOC
end

@inline function get_last_changed_locs(last_action::Pass)
    return last_action.goal_loc, INVALID_LOC
end

@inline function get_last_changed_locs(last_action::Action)
    return last_action.goal_loc, last_action.moving_loc
end

"""
For enforcing the one hive rule. Alogirthm is as follows:
articulation point = cut vertex = tile cannot be moved

GetArticulationPoints(i, d)
    # i = node, d = depth
    # initialize with some i and d = 0

    visited[i] := true
    depth[i] := d
    low[i] := d
    childCount := 0
    isArticulation := false

    for each ni in adj[i] do
        if not visited[ni] then
            parent[ni] := i
            GetArticulationPoints(ni, d + 1)
            childCount := childCount + 1
            if low[ni] ≥ depth[i] then
                isArticulation := true
            low[i] := Min (low[i], low[ni])
        else if ni ≠ parent[i] then
            low[i] := Min (low[i], depth[ni])
    if (parent[i] ≠ null and isArticulation) or (parent[i] = null and childCount > 1) then
        Output i as articulation point
"""
@inline function update_ispinned_general!(board)
    fill!(board.ispinned, false)

    @no_escape PINNED_BUFFER[2] begin
        # Allocate a `PtrArray` (see StrideArraysCore.jl) using memory from the default buffer.
        visited_dict = @alloc(eltype(true), GRID_SIZE)
        depth_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)
        low_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)
        parent_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)

        visited_dict .= false
        parent_dict .= INVALID_LOC

        for loc in board.tile_locs
            if loc >= 0
                get_pinned_tiles_general!(
                    board, visited_dict, depth_dict, low_dict, parent_dict, loc, 0
                )
                break
            end
        end
    end
end

@inline function get_pinned_tiles_general!(
    board, visited_dict, depth_dict, low_dict, parent_dict, loc, depth
)
    if loc < 0
        show(board)
        error("attempt to find pinned tiles from an invalid loc $loc")
    end
    loc_p1 = loc + 1

    @inbounds visited_dict[loc_p1] = true
    @inbounds depth_dict[loc_p1] = depth
    @inbounds low_dict[loc_p1] = depth
    child_count = 0
    is_articulation = false

    for nloc in allneighs(loc)
        if get_tile_on_board(board, nloc) == EMPTY_TILE
            continue
        end
        nloc_p1 = nloc + 1
        if @inbounds !visited_dict[nloc_p1]
            @inbounds parent_dict[nloc_p1] = loc
            get_pinned_tiles_general!(
                board, visited_dict, depth_dict, low_dict, parent_dict, nloc, depth + 1
            )
            child_count += 1
            if @inbounds low_dict[nloc_p1] >= depth_dict[loc_p1]
                is_articulation = true
            end
            @inbounds low_dict[loc_p1] = min(low_dict[loc_p1], low_dict[nloc_p1])
        elseif @inbounds nloc != parent_dict[loc_p1]
            @inbounds low_dict[loc_p1] = min(low_dict[loc_p1], depth_dict[nloc_p1])
        end
    end
    if @inbounds (parent_dict[loc_p1] != INVALID_LOC && is_articulation) ||
        (parent_dict[loc_p1] == INVALID_LOC && child_count > 1)
        @inbounds board.ispinned[loc_p1] = true
    end
end

function get_pinned_tiles(board)
    update_ispinned_general!(board)
    return copy(board.ispinned)
end
