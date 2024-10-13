function add_action(board::Board, action::Action, move_buffer; avoid_duplicates=false)
    # Do no use show(action) here because tiles might be Temporarily deleted -> string generation does not work
    if avoid_duplicates
        if move_not_duplicate(board, action, move_buffer)
            add_action!(board, action, move_buffer)
        end
    else
        add_action!(board, action, move_buffer)
    end
end

function add_action(board::Board, placement::Placement, move_buffer; avoid_duplicates=false)
    add_action!(board, placement, move_buffer)
    return nothing
end

function add_action!(board::Board, action::Action, move_buffer)
    move_buffer[board.action_index] = action_index(action)
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
    # TODO speed: ispinned does not need to be recomputed after every move
    # when an elbow is filled, or when a tile is simply pinnned, the dict only changes locally.
    if board.gameover
        return nothing
    end

    @no_escape begin
        ispinned = @alloc(eltype(true), GRID_SIZE)
        ispinned .= false
        get_pinned_tiles!(board, ispinned)

        add_placements(board, move_buffer)

        if board.queen_placed[board.current_color + 1]
            add_moves(board, ispinned, move_buffer)
        end

        if board.action_index == 1
            add_action(board, Pass(), move_buffer; avoid_duplicates=false)
        end
    end
    return nothing
end

function add_placements(board, move_buffer)
    foreach(
        loc -> foreach(
            tile -> tile != EMPTY_TILE && add_action(board, Placement(loc, tile), move_buffer),
            board.placeable_tiles[board.current_color + 1],
        ),
        board.placement_locs[board.current_color + 1],
    )
    return nothing
end

function add_moves(board, ispinned, move_buffer)
    for bug in 0x00:0x07
        for num in 0x00:MAX_NUMS[bug + 0x01]
            semi_tile = (tile_from_info(board.current_color, bug, num) >> INDEX_SHIFT) + 1
            loc = board.tile_locs[semi_tile]

            if loc != UNDERGROUND
                if loc != NOT_PLACED
                    if loc != board.moved_by_pillbug_loc
                        # Generate moves for placed tiles
                        tile = get_tile_on_board(board, loc)
                        bugmoves(board, loc, bug, get_tile_height(tile), ispinned, move_buffer)
                    end
                else
                    break
                end
            end
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
    foreach(
        loc -> add_action(board, Placement(loc, queen_tile), move_buffer),
        board.placement_locs[board.current_color + 1],
    )

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

function bugmoves(board, loc, bug, height, ispinned, move_buffer; avoid_duplicates=false)
    # Pill bug can yield special moves, even when pinned
    # Moquito can yield pill bug moves, even when pinned
    if bug == Integer(Bug.PILLBUG)
        pillbugmoves(board, loc, ispinned, move_buffer; avoid_duplicates)
    elseif bug == Integer(Bug.MOSQUITO)
        mosquitomoves(board, loc, height, ispinned, move_buffer)
    end
    if !ispinned[loc + 1]
        if bug == Integer(Bug.ANT)
            antmoves(board, loc, move_buffer; avoid_duplicates)
        elseif bug == Integer(Bug.SPIDER)
            spidermoves(board, loc, move_buffer; avoid_duplicates)
        elseif bug == Integer(Bug.QUEEN)
            queenmoves(board, loc, move_buffer; avoid_duplicates)
        elseif bug == Integer(Bug.BEETLE)
            beetlemoves(board, loc, height, move_buffer; avoid_duplicates)
        elseif bug == Integer(Bug.GRASSHOPPER)
            grasshoppermoves(board, loc, move_buffer; avoid_duplicates)
        elseif bug == Integer(Bug.LADYBUG)
            ladybugmoves(board, loc, move_buffer)
        end
    end
    return nothing
end

function mosquitomoves(board, loc, height, ispinned, move_buffer)
    if height != 1
        beetlemoves(board, loc, height, move_buffer)
    end
    neighlocs = allneighs(loc)

    for neigh in allneighs(loc)
        tile = get_tile_on_board(board, neigh)
        bug = get_tile_bug(tile)
        if tile != EMPTY_TILE && bug != Integer(Bug.MOSQUITO)
            # TODO:
            # This avoid duplicates can probably be false, duplicate moves are only added by pretending to be the pillbug
            # In fact it is probably unnecessary to pass this avoid dupicates around all the time, only set to true for pillbug special moves!
            bugmoves(board, loc, bug, height, ispinned, move_buffer; avoid_duplicates=true)
        end
    end

    return nothing
end

function pillbugmoves(board, startloc, ispinned, move_buffer; avoid_duplicates=false)
    maxdepth = 1
    if !ispinned[startloc + 1]
        moves_to_depth(board, startloc, maxdepth, move_buffer; avoid_duplicates)
    end
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
                for k in 1:(j - 1)
                    slideloc = slidelocs[k]
                    if get_tile_on_board(board, slideloc) == EMPTY_TILE
                        move = Move(loc, slideloc)
                        add_action(board, move, move_buffer; avoid_duplicates=true)
                    end
                end
            end
        end
    end

    return nothing
end

function ladybugmoves(board, startloc, move_buffer)
    maxdepth = 3
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves_to_depth_ladybug!(board, startloc, maxdepth, move_buffer)

    set_tile_on_board(board, startloc, tmp_tile)

    return nothing
end

function moves_to_depth_ladybug!(board, startloc, depth, move_buffer; cur_loc=startloc)
    if depth == 0
        if cur_loc != startloc
            add_action(board, Move(startloc, cur_loc), move_buffer; avoid_duplicates=true)
        end
        return nothing
    end
    neighlocs = allneighs(cur_loc)
    for i in 1:6
        height = get_tile_height(get_tile_on_board(board, cur_loc))
        if depth == 3 && (
                get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                canslidehigh(i, board, neighlocs, 0)
            ) ||
            depth == 2 && (
                get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                canslidehigh(i, board, neighlocs, height)
            ) ||
            depth == 1 && (
                get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE &&
                canslidehigh(i, board, neighlocs, height)
            )
            moves_to_depth_ladybug!(board, startloc, depth - 1, move_buffer; cur_loc=neighlocs[i])
        end
    end

    return nothing
end

function grasshoppermoves(board, startloc, move_buffer; avoid_duplicates=true)
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
            add_action(board, Move(startloc, loc), move_buffer; avoid_duplicates)
        end
    end
    return nothing
end

function beetlemoves(board, startloc, height, move_buffer; avoid_duplicates=false)
    neighlocs = allneighs(startloc)
    if height != 1
        # Can go anywhere, so long as it can slide with height
        for i in 1:6
            if canslidehigh(i, board, neighlocs, height)
                add_action(board, Climb(startloc, neighlocs[i]), move_buffer; avoid_duplicates)
            end
        end
        return nothing
    end
    # can go anywhere on top, or where it can slide
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    for i in 1:6
        if (
            get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
            canslidehigh(i, board, neighlocs, 1)
        ) || canslide(i, board, neighlocs)
            if get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE
                add_action(board, Climb(startloc, neighlocs[i]), move_buffer; avoid_duplicates)
            else
                add_action(board, Move(startloc, neighlocs[i]), move_buffer; avoid_duplicates)
            end
        end
    end

    set_tile_on_board(board, startloc, tmp_tile)
    return nothing
end

@inline
function canslidepillbug(i, board, neighlocs)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])

    return get_tile_height(neighleft) < 2 || get_tile_height(neighright) < 2
end

@inline
function canslidehigh(i, board, neighlocs, height)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])
    goalheight = get_tile_height(get_tile_on_board(board, neighlocs[i]))

    return get_tile_height(neighleft) < max(goalheight + 1, height) ||
           get_tile_height(neighright) < max(goalheight + 1, height)
end

function queenmoves(board, startloc, move_buffer; avoid_duplicates=false)
    maxdepth = 1
    moves_to_depth(board, startloc, maxdepth, move_buffer; avoid_duplicates)
    return nothing
end

function spidermoves(board, startloc, move_buffer; avoid_duplicates=false)
    maxdepth = 3
    moves_to_depth(board, startloc, maxdepth, move_buffer; avoid_duplicates)
    return nothing
end

function antmoves(board, startloc, move_buffer; avoid_duplicates=false)
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
                add_action(board, Move(startloc, goalloc), move_buffer; avoid_duplicates)
            end
        end
    end
    return nothing
end

function push_slidelocs!(board::Board, stack_arr, stack_ptr, loc, discovered_dict)
    neighlocs = allneighs(loc)
    if 64 in neighlocs
        print("error!")
    end
    for i in 1:6
        if canslide(i, board, neighlocs)
            if !discovered_dict[neighlocs[i] + 1]
                # push
                stack_arr[stack_ptr] = neighlocs[i]
                stack_ptr += 1

                discovered_dict[neighlocs[i] + 1] = true
            end
        end
    end
    return stack_ptr
end

function moves_to_depth(board, startloc, maxdepth, move_buffer; avoid_duplicates=false)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves_to_depth!(board, startloc, maxdepth, move_buffer)

    set_tile_on_board(board, startloc, tmp_tile)
    return nothing
end

function moves_to_depth!(board, startloc, depth, move_buffer, cur_loc=startloc, prev_loc=nothing)
    if depth == 0
        if cur_loc != startloc
            add_action(board, Move(startloc, cur_loc), move_buffer; avoid_duplicates=true)
        end
        return nothing
    end
    neighlocs = allneighs(cur_loc)
    for i in 1:6
        if canslide(i, board, neighlocs) && neighlocs[i] != prev_loc
            moves_to_depth!(board, startloc, depth - 1, move_buffer, neighlocs[i], cur_loc)
        end
    end
end

@inline
"""
From the current position, one can travel in a direcion when:

 1. the direction itself is not filled
 2. one of the two neighbouring directions is filled
"""
function canslide(i, board, neighlocs)
    return get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE && (
        (get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1]) == EMPTY_TILE) ⊻
        (get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1]) == EMPTY_TILE)
    )
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
function get_pinned_tiles!(board, pinned_tiles)
    @no_escape PINNED_BUFFER begin
        # Allocate a `PtrArray` (see StrideArraysCore.jl) using memory from the default buffer.
        visited_dict = @alloc(eltype(true), GRID_SIZE)
        depth_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)
        low_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)
        parent_dict = @alloc(eltype(board.tile_locs), GRID_SIZE)

        visited_dict .= false
        parent_dict .= INVALID_LOC

        for loc in board.tile_locs
            if loc >= 0
                get_pinned_tiles!(
                    board, pinned_tiles, visited_dict, depth_dict, low_dict, parent_dict, loc, 0
                )
                break
            end
        end
    end
end

@inbounds function get_pinned_tiles!(
    board, pinned_tiles_dict, visited_dict, depth_dict, low_dict, parent_dict, loc, depth
)
    if loc < 0
        show(board)
        error("attempt to find pinned tiles from an invalid loc $loc")
    end

    visited_dict[loc + 1] = true
    depth_dict[loc + 1] = depth
    low_dict[loc + 1] = depth
    child_count = 0
    is_articulation = false

    for nloc in allneighs(loc)
        if get_tile_on_board(board, nloc) == EMPTY_TILE
            continue
        end
        if !visited_dict[nloc + 1]
            parent_dict[nloc + 1] = loc
            get_pinned_tiles!(
                board,
                pinned_tiles_dict,
                visited_dict,
                depth_dict,
                low_dict,
                parent_dict,
                nloc,
                depth + 1,
            )
            child_count += 1
            if low_dict[nloc + 1] >= depth_dict[loc + 1]
                is_articulation = true
            end
            low_dict[loc + 1] = min(low_dict[loc + 1], low_dict[nloc + 1])
        elseif nloc != parent_dict[loc + 1]
            low_dict[loc + 1] = min(low_dict[loc + 1], depth_dict[nloc + 1])
        end
    end
    if (parent_dict[loc + 1] != INVALID_LOC && is_articulation) ||
        (parent_dict[loc + 1] == INVALID_LOC && child_count > 1)
        pinned_tiles_dict[loc + 1] = true
    end
end

function get_pinned_tiles(board)
    pinned_tiles = fill(false, GRID_SIZE)
    get_pinned_tiles!(board, pinned_tiles)
    return pinned_tiles
end
