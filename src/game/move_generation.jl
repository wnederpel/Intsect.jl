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
    validactions!(board, move_buffer, board.current_color)
    return nothing
end

function validactions!(board::Board, move_buffer, current_color)
    # Having the current color as input allows to find the valid actions for the opponent too, useful for evaluation potentially
    board.action_index = 1
    if board.gameover
        return nothing
    end

    need_to_place_queen = !board.queen_placed[current_color] && board.turn == 4
    first_placement = board.ply == 1
    second_placement = board.ply == 2

    if need_to_place_queen
        queenplacements(board, move_buffer, current_color)
    elseif first_placement
        firstplacements(board, move_buffer, current_color)
    elseif second_placement
        secondplacements(board, move_buffer, current_color)
    else
        validactions_general(board, move_buffer, current_color)
    end

    return nothing
end

"""
Valid actions for the default case
"""
function validactions_general(board::Board, move_buffer, current_color)
    add_placements(board, move_buffer, current_color)

    if board.queen_placed[current_color]
        if board.general_pinned_update_required
            update_ispinned_general!(board)
            board.general_pinned_update_required = false
        end
        add_moves(board, board.ispinned, move_buffer, current_color)
    end

    if board.action_index == 1
        add_action!(board, Pass(), move_buffer)
    end

    return nothing
end

@inline function for_placement_locs(f::Function, board)
    # Only for testing
    return for_placement_locs(f, board, board.current_color)
end

@inline function for_placement_locs(f::Function, board, current_color)
    my_pieces = board.pieces[current_color]
    their_pieces = board.pieces[other(current_color)]
    no_placement_hs = board.workspaces.no_placement_hs
    clear!(no_placement_hs)

    # Mark enemy pieces and all their neighbors as no-placement zones
    for_each_bit_set(their_pieces) do loc
        neighs = allneighs(loc)
        set!(no_placement_hs, loc)
        # Unrolled neighbor loop for better performance
        @inbounds set!(no_placement_hs, neighs[1])
        @inbounds set!(no_placement_hs, neighs[2])
        @inbounds set!(no_placement_hs, neighs[3])
        @inbounds set!(no_placement_hs, neighs[4])
        @inbounds set!(no_placement_hs, neighs[5])
        @inbounds set!(no_placement_hs, neighs[6])
    end

    # Mark my pieces as no-placement zones
    for_each_bit_set(my_pieces) do loc
        set!(no_placement_hs, loc)
    end

    # Find valid placement locations (neighbors of my pieces not in no_placement_hs)
    for_each_bit_set(my_pieces) do loc
        neighs = allneighs(loc)
        # Unrolled neighbor loop with inline checks
        @inbounds neighloc = neighs[1]
        if !no_placement_hs[neighloc]
            set!(no_placement_hs, neighloc)
            f(neighloc)
        end
        @inbounds neighloc = neighs[2]
        if !no_placement_hs[neighloc]
            set!(no_placement_hs, neighloc)
            f(neighloc)
        end
        @inbounds neighloc = neighs[3]
        if !no_placement_hs[neighloc]
            set!(no_placement_hs, neighloc)
            f(neighloc)
        end
        @inbounds neighloc = neighs[4]
        if !no_placement_hs[neighloc]
            set!(no_placement_hs, neighloc)
            f(neighloc)
        end
        @inbounds neighloc = neighs[5]
        if !no_placement_hs[neighloc]
            set!(no_placement_hs, neighloc)
            f(neighloc)
        end
        @inbounds neighloc = neighs[6]
        if !no_placement_hs[neighloc]
            set!(no_placement_hs, neighloc)
            f(neighloc)
        end
    end
    return nothing
end

function add_placements(board, move_buffer, current_color)
    for_placement_locs(board, current_color) do placement_loc
        for tile in board.placeable_tiles[current_color]
            if tile != EMPTY_TILE
                add_action!(board, Placement(placement_loc, tile), move_buffer)
            end
        end
    end
    return nothing
end

const wP::UInt8 = get_tile_from_string("wP")
const wM::UInt8 = get_tile_from_string("wM")
const bP::UInt8 = get_tile_from_string("bP")
const bM::UInt8 = get_tile_from_string("bM")

function add_moves(board, ispinned, move_buffer, current_color)
    # Moves will be stored in sets, then converted to actual moves
    move_to_set = board.workspaces.move_to_set

    # First we add the pillbug throw actions, as they move a location differnt than their own
    # In the per location loop we will add these as needed
    wP_loc = get_loc(board, wP)
    bP_loc = get_loc(board, bP)
    my_pillbug_loc = current_color == WHITE ? wP_loc : bP_loc

    my_mosquito_loc = get_loc(board, current_color == WHITE ? wM : bM)

    pillbug_throw_from = board.workspaces.pillbug_throw_from
    pillbug_throw_to = board.workspaces.pillbug_throw_to
    clear!(pillbug_throw_from)
    clear!(pillbug_throw_to)
    if my_pillbug_loc >= 0 && my_pillbug_loc != board.just_moved_loc
        pillbugmoves_throw(
            board, my_pillbug_loc, board.ispinned, pillbug_throw_from, pillbug_throw_to
        )
    end

    mosquito_throw_from = board.workspaces.mosquito_throw_from
    mosquito_throw_to = board.workspaces.mosquito_throw_to
    clear!(mosquito_throw_from)
    clear!(mosquito_throw_to)

    # Mosquito cannot throw if it's on top on the hive
    if my_mosquito_loc >= 0 &&
        my_mosquito_loc != board.just_moved_loc &&
        # mosquito can only throw if it's on the ground
        get_tile_height_unsafe(get_tile_on_board(board, my_mosquito_loc)) == 0x01
        mosq_neighs = allneighs(my_mosquito_loc)
        mosq_can_throw = wP_loc in mosq_neighs || bP_loc in mosq_neighs
        if mosq_can_throw
            pillbugmoves_throw(
                board, my_mosquito_loc, board.ispinned, mosquito_throw_from, mosquito_throw_to
            )
        end
    end

    for bug in 0x01:0x08
        if get_tile_bug_num(board.placeable_tiles[current_color][bug]) == 0
            continue
        end
        for num in 0x00:MAX_NUMS[bug]
            semi_tile = tile_from_info_as_index(current_color, bug, num)
            @inbounds loc = board.tile_locs[semi_tile + 1]

            if loc == NOT_PLACED
                break
            end
            if loc == UNDERGROUND || loc == board.just_moved_loc || loc == INVALID_LOC
                continue
            end
            # Generate moves for placed tiles
            tile = get_tile_on_board(board, loc)
            height = get_tile_height_unsafe(tile)
            clear!(move_to_set)
            bugmoves(board, loc, bug, height, ispinned, move_to_set)
            # Imagine we now how have the move_to_set filled, we then need to add the throws (optionally)
            if pillbug_throw_from[loc]
                remove!(pillbug_throw_from, loc)
                for_each_bit_set(pillbug_throw_to) do goal_loc
                    set!(move_to_set, goal_loc)
                end
            end
            if mosquito_throw_from[loc]
                remove!(mosquito_throw_from, loc)
                for_each_bit_set(mosquito_throw_to) do goal_loc
                    set!(move_to_set, goal_loc)
                end
            end
            moves_are_climbs = height > 0x01

            for_each_bit_set(move_to_set) do goal_loc
                if moves_are_climbs || (get_tile_on_board(board, goal_loc) != EMPTY_TILE)
                    add_action!(board, Climb(loc, goal_loc), move_buffer)
                else
                    add_action!(board, Move(loc, goal_loc), move_buffer)
                end
            end
        end
    end
    # Also add the remaining pullbug throw moves, these move pieces of the other color
    for_each_bit_set(pillbug_throw_from) do moving_loc
        for_each_bit_set(pillbug_throw_to) do goal_loc
            add_action!(board, Move(moving_loc, goal_loc), move_buffer)
        end
    end
    for_each_bit_set(mosquito_throw_from) do moving_loc
        for_each_bit_set(mosquito_throw_to) do goal_loc
            if pillbug_throw_from[moving_loc] && pillbug_throw_to[goal_loc]
                return nothing  # already added
            end
            add_action!(board, Move(moving_loc, goal_loc), move_buffer)
        end
    end
    return nothing
end

"""
valid actions for when the queen must be placed
"""
function queenplacements(board, move_buffer, current_color)
    queen_tile = current_color == WHITE ? wQ : bQ

    for_placement_locs(board) do placement_loc
        add_action!(board, Placement(placement_loc, queen_tile), move_buffer)
    end
    return nothing
end

"""
valid actions for when the first move is made
"""
function firstplacements(board, move_buffer, current_color)
    for tile in board.placeable_tiles[current_color]
        if tile != EMPTY_TILE && get_tile_bug(tile) != Integer(Bug.QUEEN)
            add_action!(board, Placement(MID, tile), move_buffer)
        end
    end
    return nothing
end

"""
valid actions for second placement (first placement by black)
"""
function secondplacements(board, move_buffer, current_color)
    for loc in allneighs(MID)
        for tile in board.placeable_tiles[current_color]
            if tile != EMPTY_TILE && get_tile_bug(tile) != Integer(Bug.QUEEN)
                add_action!(board, Placement(loc, tile), move_buffer)
            end
        end
    end
    return nothing
end

@inline function bugmoves(board, loc, bug, height, ispinned, move_to_set::HexSet)

    # Pill bug can yield special moves, even when pinned
    # Mosquito can yield pill bug moves, even when pinned
    # However throws, are already handled in the calling function

    # Beetle can move on top op hive, even when pinned
    # The mosquito can do so too
    if bug == Integer(Bug.BEETLE) && (!ispinned[loc] || height != 1)
        beetlemoves(board, loc, height, move_to_set)
    elseif bug == Integer(Bug.MOSQUITO) && (!ispinned[loc] || height != 1)
        mosquitomoves(board, loc, height, ispinned, move_to_set)

    elseif !ispinned[loc]
        if bug == Integer(Bug.PILLBUG)
            pillbugmoves_normal(board, loc, ispinned, move_to_set)

        elseif bug == Integer(Bug.ANT)
            antmoves(board, loc, move_to_set)

        elseif bug == Integer(Bug.SPIDER)
            spidermoves(board, loc, move_to_set)

        elseif bug == Integer(Bug.QUEEN)
            queenmoves(board, loc, move_to_set)

        elseif bug == Integer(Bug.GRASSHOPPER)
            grasshoppermoves(board, loc, move_to_set)

        elseif bug == Integer(Bug.LADYBUG)
            ladybugmoves(board, loc, move_to_set)
        end
    end
    return nothing
end

function mosquitomoves(board, loc, height, ispinned, move_to_set::HexSet)
    if height > 1
        beetlemoves(board, loc, height, move_to_set)
        return nothing
    end

    if ispinned[loc]
        return nothing
    end
    # bit set where the index of the bits corresponds with the bug enum
    bugs_touched = 0
    for neigh in allneighs(loc)
        tile = get_tile_on_board(board, neigh)
        bug = get_tile_bug(tile)
        bugs_touched |= 1 << bug
    end

    # Check bugs at index 1 to 7 (8 is mosquito, 0 is empty tile)
    if bugs_touched & 1 << Integer(Bug.ANT) != 0
        # It's Important that the antmoves are added first, because the antmoves will store the current move_to_set as the ant_reachable_hs in the move store
        antmoves(board, loc, move_to_set)
    else
        if bugs_touched & (1 << Integer(Bug.QUEEN) | 1 << Integer(Bug.PILLBUG)) != 0
            queenmoves(board, loc, move_to_set)
        end
        if bugs_touched & (1 << Integer(Bug.SPIDER)) != 0
            spidermoves(board, loc, move_to_set)
        end
    end
    if bugs_touched & (1 << Integer(Bug.GRASSHOPPER)) != 0
        grasshoppermoves(board, loc, move_to_set)
    end
    if bugs_touched & (1 << Integer(Bug.LADYBUG)) != 0
        ladybugmoves(board, loc, move_to_set)
    end
    if bugs_touched & (1 << Integer(Bug.BEETLE)) != 0
        beetlemoves(board, loc, height, move_to_set)
    end

    return nothing
end

function pillbugmoves_throw(board, startloc, ispinned, from_locs_hs::HexSet, to_locs_hs::HexSet)
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
                if get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE
                    set!(to_locs_hs, neighlocs[i])
                end
                slidelocs[j] = neighlocs[i]
                j += 1
            end
        end

        for i in 1:6
            loc = neighlocs[i]
            tile = get_tile_on_board(board, loc)
            if (
                tile != EMPTY_TILE &&
                !ispinned[loc] &&
                loc != board.just_moved_loc &&
                get_tile_height(tile) == 1 &&
                canslidepillbug(i, board, neighlocs)
            )
                set!(from_locs_hs, loc)
            end
        end
    end
end

@inline function pillbugmoves_normal(board, startloc, ispinned, move_to_set::HexSet)
    if !ispinned[startloc]
        # pillbug moves before mosquito, so we do not have to remove duplicates
        move_1(board, startloc, move_to_set)
    end
    return nothing
end

function ladybugmoves(board, startloc, move_to_set::HexSet)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    visited_step_2 = board.workspaces.ladybug_visited_step_2
    Intsect.clear!(visited_step_2)

    neighlocs = allneighs(startloc)

    # Step 1: Iterate over step_1 locations
    @inbounds for i in 1:6
        step_1_loc = neighlocs[i]
        step_1_tile = get_tile_on_board(board, step_1_loc)

        # Early exit: must be occupied
        step_1_tile == EMPTY_TILE && continue

        # Inline canslidehigh check for step 1
        step_1_i_left = i == 1 ? 6 : i - 1
        step_1_i_right = i == 6 ? 1 : i + 1
        neighleft_tile = get_tile_on_board(board, neighlocs[step_1_i_left])
        neighright_tile = get_tile_on_board(board, neighlocs[step_1_i_right])

        # Extract heights efficiently using bitwise operations
        step_1_height_raw = step_1_tile & 0x03
        neighleft_height = neighleft_tile == EMPTY_TILE ? 0x00 : (neighleft_tile & 0x03) + 0x01
        neighright_height = neighright_tile == EMPTY_TILE ? 0x00 : (neighright_tile & 0x03) + 0x01
        step_1_height = step_1_height_raw + 0x01
        max_height_1 = step_1_height + 0x01

        (neighleft_height < max_height_1 || neighright_height < max_height_1) || continue

        # Step 2: Iterate over step_2 locations
        step_2_locs = allneighs(step_1_loc)
        @inbounds for j in 1:6
            step_2_loc = step_2_locs[j]
            step_2_tile = get_tile_on_board(board, step_2_loc)

            # Early exits
            step_2_tile == EMPTY_TILE && continue
            visited_step_2[step_2_loc] && continue

            # Inline canslidehigh check for step 2
            step_2_j_left = j == 1 ? 6 : j - 1
            step_2_j_right = j == 6 ? 1 : j + 1
            step_2_left_tile = get_tile_on_board(board, step_2_locs[step_2_j_left])
            step_2_right_tile = get_tile_on_board(board, step_2_locs[step_2_j_right])

            step_2_height_raw = step_2_tile & 0x03
            step_2_left_height =
                step_2_left_tile == EMPTY_TILE ? 0x00 : (step_2_left_tile & 0x03) + 0x01
            step_2_right_height =
                step_2_right_tile == EMPTY_TILE ? 0x00 : (step_2_right_tile & 0x03) + 0x01
            step_2_height = step_2_height_raw + 0x01
            height_from_1_to_2 = step_1_height + 0x01

            # Compute max inline to avoid function call
            max_height_2 = step_2_height + 0x01
            max_height_2 = max_height_2 > height_from_1_to_2 ? max_height_2 : height_from_1_to_2

            (step_2_left_height < max_height_2 || step_2_right_height < max_height_2) || continue

            set!(visited_step_2, step_2_loc)

            # Step 3: Iterate over step_3 locations (final landing spots)
            step_3_locs = allneighs(step_2_loc)
            @inbounds for k in 1:6
                step_3_loc = step_3_locs[k]
                step_3_tile = get_tile_on_board(board, step_3_loc)

                # Must land on empty, not already in move_to_set
                step_3_tile != EMPTY_TILE && continue
                move_to_set[step_3_loc] && continue

                # Inline canslidehigh check for step 3
                step_3_k_left = k == 1 ? 6 : k - 1
                step_3_k_right = k == 6 ? 1 : k + 1
                step_3_left_tile = get_tile_on_board(board, step_3_locs[step_3_k_left])
                step_3_right_tile = get_tile_on_board(board, step_3_locs[step_3_k_right])

                step_3_left_height =
                    step_3_left_tile == EMPTY_TILE ? 0x00 : (step_3_left_tile & 0x03) + 0x01
                step_3_right_height =
                    step_3_right_tile == EMPTY_TILE ? 0x00 : (step_3_right_tile & 0x03) + 0x01
                # step_3 is EMPTY (goalheight = 0), so max is just the incoming height
                max_height_3 = step_2_height + 0x01

                (step_3_left_height < max_height_3 || step_3_right_height < max_height_3) ||
                    continue

                set!(move_to_set, step_3_loc)
            end
        end
    end

    remove!(move_to_set, startloc)
    set_tile_on_board(board, startloc, tmp_tile)

    return nothing
end

function grasshoppermoves(board, startloc, move_to_set::HexSet)
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
            set!(move_to_set, loc)
        end
    end
    return nothing
end

function beetlemoves(board, startloc, height, move_to_set::HexSet)
    neighlocs = allneighs(startloc)
    if height != 1
        # Can go anywhere, so long as it can slide with height
        for i in 1:6
            if canslidehigh(i, board, neighlocs, height)
                set!(move_to_set, neighlocs[i])
            end
        end
        return nothing
    end
    # can go anywhere on top, or where it can slide
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    for i in 1:6
        # Either slide high on top of a tile, or slide normally to an empty tile
        if (
            get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
            canslidehigh(i, board, neighlocs, 1)
        ) || (get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE && canslide(i, board, neighlocs))
            set!(move_to_set, neighlocs[i])
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

@inline function queenmoves(board, startloc, move_to_set::HexSet)
    move_1(board, startloc, move_to_set)
    return nothing
end

function spidermoves(board, startloc, move_to_set::HexSet)
    move_3(board, startloc, move_to_set)
    return nothing
end

function antmoves(board, startloc, move_to_set::HexSet)
    tmp_tile = get_tile_on_board(board, startloc)
    move_entry_hash = board.location_hash ⊻ get_location_hash_value(startloc)

    move_entry = board.move_store[(move_entry_hash & MOVE_STORE_MASK) + 1]
    stored_hash = move_entry.location_hash
    stored_moves = move_entry.ant_reachable_hs

    if stored_hash == move_entry_hash && stored_moves[startloc]
        union!(move_to_set, stored_moves)
        remove!(move_to_set, startloc)
        return nothing
    end

    # Temporarily remove the tile to find where it can move to
    set_tile_on_board(board, startloc, EMPTY_TILE)
    @no_escape begin
        stack_arr = @alloc(Int, GRID_SIZE)
        stack_ptr = 1

        # push startloc and mark as visited
        stack_arr[stack_ptr] = startloc
        stack_ptr += 1
        set!(move_to_set, startloc)

        while stack_ptr != 1
            # pop
            loc = stack_arr[stack_ptr - 1]
            stack_ptr -= 1

            neighlocs = allneighs(loc)
            slide_neighs = get_slide_neighs(board, neighlocs)
            # slide_neighs is a number with bits for the slidable neighbours
            while slide_neighs != 0
                slide_neigh_i = trailing_zeros(slide_neighs) + 1
                slide_neighs &= slide_neighs - 1

                @inbounds neigh_loc = neighlocs[slide_neigh_i]
                # Only push if not already visited
                if !move_to_set[neigh_loc]
                    set!(move_to_set, neigh_loc)
                    @inbounds stack_arr[stack_ptr] = neigh_loc
                    stack_ptr += 1
                end
            end
        end
        set_tile_on_board(board, startloc, tmp_tile)
    end

    if (stored_hash != move_entry_hash) && count_ones(move_to_set) > 10
        stored_moves = move_entry.ant_reachable_hs
        overwrite!(stored_moves, move_to_set)
        entry = MoveStoreEntry(move_entry_hash, stored_moves)
        board.move_store[(move_entry_hash & MOVE_STORE_MASK) + 1] = entry
    end

    remove!(move_to_set, startloc)

    return nothing
end

@inline function push_slidelocs!(board::Board, stack_arr, stack_ptr, loc, reachable_hs::HexSet)
    neighlocs = allneighs(loc)
    for i in 1:6
        if !get(reachable_hs, neighlocs[i])
            if canslide(i, board, neighlocs)
                @inbounds stack_arr[stack_ptr] = neighlocs[i]
                stack_ptr += 1

                set!(reachable_hs, neighlocs[i])
            end
        end
    end
    return stack_ptr
end

@inline function move_3(board, startloc, move_to_set::HexSet)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves_to_depth!(board, startloc, 3, move_to_set)

    set_tile_on_board(board, startloc, tmp_tile)
    return nothing
end

@inline function move_1(board, startloc, move_to_set::HexSet)
    neighlocs = allneighs(startloc)
    slide_neighs = get_slide_neighs(board, neighlocs)
    # slide_neighs is a number with bits for the slidable neighbours
    while slide_neighs != 0
        slide_neigh_i = trailing_zeros(slide_neighs) + 1
        slide_neighs &= slide_neighs - 1

        set!(move_to_set, neighlocs[slide_neigh_i])
    end
    return nothing
end

@inline function moves_to_depth!(
    board, startloc, depth, move_to_set::HexSet; cur_loc=startloc, prev_loc=nothing
)
    if depth == 0
        if cur_loc != startloc
            set!(move_to_set, cur_loc)
        end
        return nothing
    end

    neighlocs = allneighs(cur_loc)
    slide_neighs = get_slide_neighs(board, neighlocs)
    # slide_neighs is a number with bits for the slidable neighbours
    while slide_neighs != 0
        slide_neigh_i = trailing_zeros(slide_neighs) + 1
        slide_neighs &= slide_neighs - 1

        if neighlocs[slide_neigh_i] == prev_loc
            continue
        end
        moves_to_depth!(
            board,
            startloc,
            depth - 1,
            move_to_set;
            cur_loc=neighlocs[slide_neigh_i],
            prev_loc=cur_loc,
        )
    end
end

"""
From the current position, one can travel in a direcion when:

 1. the direction itself is not filled
 2. one of the two neighbouring directions is filled
"""
@inline function canslide(i, board, neighlocs)
    @inbounds left_neigh = neighlocs[i == 1 ? 6 : i - 1]
    @inbounds right_neigh = neighlocs[i == 6 ? 1 : i + 1]
    return get_tile_on_board(board, @inbounds neighlocs[i]) == EMPTY_TILE && (
        (@inbounds get_tile_on_board(board, left_neigh) == EMPTY_TILE) ⊻
        (@inbounds get_tile_on_board(board, right_neigh) == EMPTY_TILE)
    )
end

@inline function get_slide_neighs(board, all_neighbours)
    # Number, the bits are used to indicate the presence of a piece
    occupied = 0
    for i in 6:-1:1
        occupied <<= 1
        @inbounds if get_tile_on_board(board, all_neighbours[i]) != EMPTY_TILE
            occupied |= 1
            # wrap around
            occupied |= 1 << 6
            occupied |= 1 << 12
        end
    end

    slidable = ((~occupied & ((occupied << 1) ⊻ (occupied >>> 1))) >> 6) & (2^6 - 1)
    return slidable
end

@inline function get_pinned_tiles!(board::Board, last_goal_loc, last_moving_loc; inverse=false)
    return board.general_pinned_update_required = true
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
        # Maybe that speeds things up, for now just returning that a full update is required is faster
        # elseif is_last_change_elbow(board)
        #     update_ispinned_elbow!(board)
        #     return nothing
    end
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
    neighlocs = allneighs(loc)
    neighs = 0
    neigh = INVALID_LOC
    for i in 1:6
        if neighlocs[i] == skip_loc
            continue
        end
        if get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE
            neighs += 1
            neigh = neighlocs[i]
            if neighs > 1
                return false, INVALID_LOC
            end
        end
    end
    if neighs == 0
        return false, INVALID_LOC
    end
    return true, neigh
end

@inline function has_one_neigh(board, loc)
    return has_one_neigh_and_get(board, loc)[1]
end

@inline function update_ispinned_simple!(
    board, last_goal_loc, goal_neigh, last_moving_loc, moving_neigh
)
    if moving_neigh >= 0
        remove!(board.ispinned, moving_neigh)
    end

    # If the goal_loc exists,
    # Then, at the goal loc, the neigh becomes stuck and you are unstuck
    if last_goal_loc >= 0
        remove!(board.ispinned, last_goal_loc)
        set!(board.ispinned, goal_neigh)
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
@inline function update_ispinned_general!(board::Board)
    clear!(board.ispinned)

    pinned_entry = board.pinned_store[(board.location_hash & PINNED_STORE_MASK) + 1]
    stored_hash = pinned_entry.location_hash

    if stored_hash == board.location_hash
        union!(board.ispinned, pinned_entry.pinned_pieces_hs)
        return nothing
    end

    visited = board.workspaces.ispinned_visited
    clear!(visited)

    @no_escape PINNED_BUFFER[2] begin
        # Allocate a `PtrArray` (see StrideArraysCore.jl) using memory from the default buffer.
        depth_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)
        low_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)
        parent_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)

        parent_dict .= INVALID_LOC

        if board.queen_pos_white >= 0
            start_loc = board.queen_pos_white
        else
            start_loc = board.queen_pos_black
        end
        get_pinned_tiles_general!(board, visited, depth_dict, low_dict, parent_dict, start_loc, 0)
    end

    stored_pinned = pinned_entry.pinned_pieces_hs
    overwrite!(stored_pinned, board.ispinned)
    entry = PinnedStoreEntry(board.location_hash, stored_pinned)
    board.pinned_store[(board.location_hash & PINNED_STORE_MASK) + 1] = entry

    return nothing
end

@inline function get_pinned_tiles_general!(
    board, visited::HexSet, depth_dict, low_dict, parent_dict, loc, depth
)
    loc_p1 = loc + 1

    set!(visited, loc)
    @inbounds depth_dict[loc_p1] = depth
    @inbounds low_dict[loc_p1] = depth
    child_count = 0
    is_articulation = false

    for nloc in allneighs(loc)
        if get_tile_on_board(board, nloc) == EMPTY_TILE
            continue
        end
        nloc_p1 = nloc + 1
        if !visited[nloc]
            @inbounds parent_dict[nloc_p1] = loc
            get_pinned_tiles_general!(
                board, visited, depth_dict, low_dict, parent_dict, nloc, depth + 1
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
        set!(board.ispinned, loc)
    end
    return nothing
end

function get_pinned_tiles(board)
    update_ispinned_general!(board)
    return copy(board.ispinned)
end
