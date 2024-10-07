function add_action(board::Board, action::Action; avoid_duplicates=false)
    # Do no use show(action) here because tiles might be Temporarily deleted -> string generation does not work
    if avoid_duplicates
        if move_not_duplicate(board, action)
            add_action!(board, action)
        end
    else
        add_action!(board, action)
    end
end

function add_action(board::Board, placement::Placement; avoid_duplicates=false)
    add_action!(board, placement)
end

function add_action!(board::Board, action::Action)
    board.validactions[board.action_index] = action_index(action)
    board.action_index += 1
end

function validactions_indices(board)
    validactions!(board)
    return extract_valid_actions_index(board)
end

function validactions(board)
    return ALL_ACTIONS[validactions_indices(board)]
end

function extract_valid_actions_index(board)
    tmp = board.action_index
    board.action_index = 1
    return board.validactions[1:(tmp - 1)]
end

function extract_valid_actions(board)
    tmp = board.action_index
    board.action_index = 1
    return ALL_ACTIONS[board.validactions[1:(tmp - 1)]]
end

function validactions!(board::Board)
    board.action_index = 1

    need_to_place_queen = !board.queen_placed[board.current_color + 1] && board.turn == 4
    first_placement = board.ply == 1
    second_placement = board.ply == 2

    if need_to_place_queen
        queenplacements(board)
    elseif first_placement
        firstplacements(board)
    elseif second_placement
        secondplacements(board)
    else
        validactions_general(board)
    end

    return nothing
end

"""
Valid actions for the default case
"""
function validactions_general(board::Board)
    # TODO speed: ispinned does not need to be recomputed after every move
    # when an elbow is filled, or when a tile is simply pinnned, the dict only changes locally.
    if board.gameover
        return nothing
    end

    @no_escape begin
        ispinned = @alloc(eltype(true), GRID_SIZE)
        ispinned .= false
        get_pinned_tiles!(board, ispinned)

        add_placements(board)

        if board.queen_placed[board.current_color + 1]
            add_moves(board, ispinned)
        end

        if board.action_index == 1
            add_action(board, Pass(); avoid_duplicates=false)
        end
    end
    return nothing
end

function add_placements(board)
    foreach(
        loc -> foreach(
            tile -> tile != EMPTY_TILE && add_action(board, Placement(loc, tile)),
            board.placeable_tiles[board.current_color + 1],
        ),
        board.placement_locs[board.current_color + 1],
    )
    # for loc in board.placement_locs[board.current_color + 1]
    #     for tile in board.placeable_tiles[board.current_color + 1]
    #         if tile != EMPTY_TILE
    #             add_action(board, Placement(loc, tile))
    #         end
    #     end
    # end
    return nothing
end

function add_moves(board, ispinned)
    for bug in 0x00:0x07
        for num in 0x00:MAX_NUMS[bug + 0x01]
            semi_tile = (tile_from_info(board.current_color, bug, num) >> INDEX_SHIFT) + 1
            loc = board.tile_locs[semi_tile]

            if loc != UNDERGROUND
                if loc != NOT_PLACED
                    if loc != board.moved_by_pillbug_loc
                        # Generate moves for placed tiles
                        tile = get_tile_on_board(board, loc)
                        bugmoves(board, loc, bug, get_tile_height(tile), ispinned)
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
function queenplacements(board)
    queen_tile =
        board.current_color == WHITE ? get_tile_from_string(board, "wQ") :
        get_tile_from_string(board, "bQ")
    foreach(
        loc -> add_action(board, Placement(loc, queen_tile)),
        board.placement_locs[board.current_color + 1],
    )

    return nothing
end

"""
valid actions for when the first move is made
"""
function firstplacements(board)
    foreach(
        tile -> tile != EMPTY_TILE && add_action(board, Placement(MID, tile)),
        filter(
            tile -> get_tile_bug(tile) != Integer(Bug.QUEEN),
            board.placeable_tiles[board.current_color + 1],
        ),
    )
    return nothing
end

"""
valid actions for second placement (first placement by black)
"""
function secondplacements(board)
    foreach(
        loc -> foreach(
            tile -> tile != EMPTY_TILE && add_action(board, Placement(loc, tile)),
            filter(
                tile -> get_tile_bug(tile) != Integer(Bug.QUEEN),
                board.placeable_tiles[board.current_color + 1],
            ),
        ),
        allneighs(MID),
    )
    return nothing
end

function bugmoves(board, loc, bug, height, ispinned; avoid_duplicates=false)
    # Pill bug can yield special moves, even when pinned
    # Moquito can yield pill bug moves, even when pinned
    if bug == Integer(Bug.PILLBUG)
        pillbugmoves(board, loc, ispinned; avoid_duplicates)
    elseif bug == Integer(Bug.MOSQUITO)
        mosquitomoves(board, loc, height, ispinned)
    end
    if !ispinned[loc + 1]
        if bug == Integer(Bug.ANT)
            antmoves(board, loc; avoid_duplicates)
        elseif bug == Integer(Bug.SPIDER)
            spidermoves(board, loc; avoid_duplicates)
        elseif bug == Integer(Bug.QUEEN)
            queenmoves(board, loc; avoid_duplicates)
        elseif bug == Integer(Bug.BEETLE)
            beetlemoves(board, loc, height; avoid_duplicates)
        elseif bug == Integer(Bug.GRASSHOPPER)
            grasshoppermoves(board, loc; avoid_duplicates)
        elseif bug == Integer(Bug.LADYBUG)
            ladybugmoves(board, loc; avoid_duplicates)
        end
    end
    return nothing
end

function mosquitomoves(board, loc, height, ispinned)
    if height != 1
        beetlemoves(board, loc, height)
    end
    neighlocs = allneighs(loc)
    neighbugs = []
    foreach(i -> begin
        neigh = neighlocs[i]
        tile = get_tile_on_board(board, neigh)
        bug = get_tile_bug(tile)
        if tile != EMPTY_TILE && bug != Integer(Bug.MOSQUITO)
            push!(neighbugs, bug)
        end
    end, 1:6)
    for bug in neighbugs
        bugmoves(board, loc, bug, height, ispinned; avoid_duplicates=true)
    end
    return nothing
end

function pillbugmoves(board, startloc, ispinned; avoid_duplicates=false)
    maxdepth = 1
    if !ispinned[startloc + 1]
        moves_to_depth(board, startloc, maxdepth; avoid_duplicates)
    end
    # Ladybug also has special moves
    # For all surrounding tiles, if they are not pinned, and did not just move,
    # and can slide on the pillbug, and the tile is not stacked
    # they can be slid on top of the pillbug, and then slid off
    neighlocs = allneighs(startloc)
    # For each neigh, see if it can slide high
    canslide = map(i -> canslidepillbug(i, board, neighlocs), 1:6)
    slidelocs = map(i -> neighlocs[i], filter(i -> canslide[i], 1:6))

    foreach(
        i -> begin
            loc = neighlocs[i]
            for slideloc in slidelocs
                move = Move(loc, slideloc)
                if get_tile_on_board(board, slideloc) == EMPTY_TILE
                    add_action(board, move; avoid_duplicates=true)
                end
            end
        end,
        filter(
            i -> begin
                loc = neighlocs[i]
                tile = get_tile_on_board(board, loc)
                return tile != EMPTY_TILE &&
                       !ispinned[loc + 1] &&
                       loc != board.just_moved_loc &&
                       get_tile_height(tile) == 1 &&
                       canslide[i]
            end,
            1:6,
        ),
    )
    return nothing
end

function ladybugmoves(board, startloc; avoid_duplicates=false)
    maxdepth = 3
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves = Set()
    moves_to_depth_ladybug!(board, startloc, maxdepth, moves)
    for move in moves
        add_action(board, move; avoid_duplicates)
    end

    set_tile_on_board(board, startloc, tmp_tile)

    return nothing
end

function moves_to_depth_ladybug!(board, startloc, depth, moves; cur_loc=startloc)
    if depth == 0
        if cur_loc != startloc
            push!(moves, Move(startloc, cur_loc))
        end
        return nothing
    end
    neighlocs = allneighs(cur_loc)
    foreach(
        slideloc -> moves_to_depth_ladybug!(board, startloc, depth - 1, moves; cur_loc=slideloc),
        map(
            i -> neighlocs[i],
            filter(
                i -> begin
                    height = get_tile_height(get_tile_on_board(board, cur_loc))
                    depth == 3 &&
                        return get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                               canslidehigh(i, board, neighlocs, 0)
                    depth == 2 &&
                        return get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                               canslidehigh(i, board, neighlocs, height)
                    depth == 1 &&
                        return get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE &&
                               canslidehigh(i, board, neighlocs, height)
                end,
                1:6,
            ),
        ),
    )
end

function grasshoppermoves(board, startloc; avoid_duplicates=true)
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
            add_action(board, Move(startloc, loc); avoid_duplicates)
        end
    end
    return nothing
end

function beetlemoves(board, startloc, height; avoid_duplicates=false)
    neighlocs = allneighs(startloc)
    if height != 1
        # Can go anywhere, so long as it can slide with height
        map(
            neigh -> begin
                add_action(board, Climb(startloc, neighlocs[neigh]); avoid_duplicates)
            end,
            filter(i -> canslidehigh(i, board, neighlocs, height), 1:6),
        )
        return nothing
    else
        # can go anywhere on top, or where it can slide
        tmp_tile = get_tile_on_board(board, startloc)
        set_tile_on_board(board, startloc, EMPTY_TILE)
        map(
            neigh -> begin
                if get_tile_on_board(board, neighlocs[neigh]) != EMPTY_TILE
                    add_action(board, Climb(startloc, neighlocs[neigh]); avoid_duplicates)
                else
                    add_action(board, Move(startloc, neighlocs[neigh]); avoid_duplicates)
                end
            end,
            filter(
                i ->
                    (
                        get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                        canslidehigh(i, board, neighlocs, 1)
                    ) || canslide(i, board, neighlocs),
                1:6,
            ),
        )
        set_tile_on_board(board, startloc, tmp_tile)
        return nothing
    end
end

function canslidepillbug(i, board, neighlocs)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])

    return get_tile_height(neighleft) < 2 || get_tile_height(neighright) < 2
end

function canslidehigh(i, board, neighlocs, height)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])
    goalheight = get_tile_height(get_tile_on_board(board, neighlocs[i]))

    return get_tile_height(neighleft) < max(goalheight + 1, height) ||
           get_tile_height(neighright) < max(goalheight + 1, height)
end

function queenmoves(board, startloc; avoid_duplicates=false)
    maxdepth = 1
    moves_to_depth(board, startloc, maxdepth; avoid_duplicates)
    return nothing
end

function spidermoves(board, startloc; avoid_duplicates=false)
    maxdepth = 3
    moves_to_depth(board, startloc, maxdepth; avoid_duplicates)
    return nothing
end

function antmoves(board, startloc; avoid_duplicates=false)
    tmp_tile = get_tile_on_board(board, startloc)
    # Temporarily remove the tile to find where it can move to
    set_tile_on_board(board, startloc, EMPTY_TILE)
    discovered_dict = DefaultDict(false)
    stack = Stack{Int}()

    push!(stack, startloc)

    while !isempty(stack)
        loc = pop!(stack)
        push_slidelocs!(board, stack, loc, discovered_dict)
    end
    set_tile_on_board(board, startloc, tmp_tile)

    for (goalloc, discovered) in discovered_dict
        if discovered && goalloc != startloc
            add_action(board, Move(startloc, goalloc); avoid_duplicates)
        end
    end
    return nothing
end

function moves_to_depth(board, startloc, maxdepth; avoid_duplicates=false)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves = Set()
    moves_to_depth!(board, startloc, maxdepth, moves)
    for move in moves
        add_action(board, move; avoid_duplicates)
    end

    set_tile_on_board(board, startloc, tmp_tile)
    return nothing
end

function moves_to_depth!(board, startloc, depth, moves, cur_loc=startloc, prev_loc=nothing)
    if depth == 0
        if cur_loc != startloc
            push!(moves, Move(startloc, cur_loc))
        end
        return nothing
    end
    neighlocs = allneighs(cur_loc)
    foreach(
        slideloc -> moves_to_depth!(board, startloc, depth - 1, moves, slideloc, cur_loc),
        map(
            i -> neighlocs[i],
            filter(i -> canslide(i, board, neighlocs) && neighlocs[i] != prev_loc, 1:6),
        ),
    )
end

"""
From the current position, one can travel in a direcion when:

 1. the direction itself is not filled
 2. one of the two neighbouring directions is filled
"""
function push_slidelocs!(board::Board, stack::Stack, loc, discovered_dict)
    neighlocs = allneighs(loc)
    if 64 in neighlocs
        print("error!")
    end
    foreach(
        slideloc -> begin
            if !discovered_dict[slideloc]
                push!(stack, slideloc)
                discovered_dict[slideloc] = true
            end
        end,
        map(i -> neighlocs[i], filter(i -> canslide(i, board, neighlocs), 1:6)),
    )
end

function push_slidelocs!(board::Board, stack::Stack, depth, discovered_dict, loc)
    neighlocs = allneighs(loc)
    if 64 in neighlocs
        print("error!")
    end
    foreach(
        slideloc -> begin
            if !discovered_dict[slideloc]
                push!(stack, slideloc)
                depth[slideloc] = depth[loc] + 1
            end
        end,
        map(i -> neighlocs[i], filter(i -> canslide(i, board, neighlocs), 1:6)),
    )
end

@inline function canslide(i, board, neighlocs)
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
    @no_escape begin
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

function get_pinned_tiles!(
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
