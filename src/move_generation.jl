function add_action(board::Board, action::Action)
    board.validactions[board.action_index] = action
    board.action_index += 1
end

function validactions(board::Board)
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
    # TODO speed: maybe split in two functions, one for placement and one for moves, avoid queen placed checked for each tile, more same checks on all tiles can be extracted perhaps.  
    # TODO speed: be more carefull about the bugs for which movements should be generated
    # Once all bugs of type are placed no more placements should be generated for that bug

    # TODO speed: ispinned does not need to be recomputed after every move
    # when an elbow is filled, or when a tile is simply pinnned, the dict only changes locally.
    ispinned = get_pinned_tiles(board)

    my_placement_locs = generate_placement_locs(board, board.current_color)

    if board.gameover
        return nothing
    end

    # TODO speed: Check if this is necessary
    # This might be a bit slow, because of allocations, but a copy is slower, normal vec or sized vec is also slower
    placements_genereated = MVector{8,Bool}(false, false, false, false, false, false, false, false)

    # TODO speed: investigate custom interator that only interates over the right color (and perhaps more)
    # This loop pattern is repeated in the other validactions functions

    # TODO speed: use a preallocated buffer (check https://docs.juliahub.com/General/Bumper/stable/)

    # TODO func: looks like im missing placements..
    # Actually I am missing queen moves
    for (semi_tile, loc) in enumerate(board.tile_locs)
        # only generate moves for tiles of the current color 
        # != because the index is 1-based, tiles are 0-based
        if semi_tile % 2 != board.current_color
            # only generate moves for tiles that are placed
            if loc != INVALID_LOC && loc != UNDERGROUND
                if !all(placements_genereated) && loc == NOT_PLACED
                    # Generate placements for unplaced tiles that are the first of their kind
                    tile = get_tile_unplaced(semi_tile)
                    bug = get_tile_bug(tile)
                    if !placements_genereated[bug + 1]
                        generate_placements(board, my_placement_locs, tile)
                        placements_genereated[bug + 1] = true
                    end
                elseif (
                    !ispinned[loc] &&
                    board.queen_placed[board.current_color + 1] &&
                    loc != board.moved_by_pillbug_loc
                )

                    # Generate moves for placed tiles
                    tile = get_tile_on_board(board, loc)
                    bug = get_tile_bug(tile)
                    bugmoves(board, loc, bug, get_tile_height(tile), ispinned)
                end
            end
        end
    end
    if board.action_index == 1
        add_action(board, Pass())
    end
    return nothing
end

"""
valid actions for when the queen must be placed
"""
function queenplacements(board)
    my_placement_locs = generate_placement_locs(board, board.current_color)

    generate_placements(
        board,
        my_placement_locs,
        board.current_color == WHITE ? get_tile_from_string(board, "wQ") :
        get_tile_from_string(board, "bQ"),
    )

    return nothing
end

"""
valid actions for when the first move is made
"""
function firstplacements(board)
    my_placement_locs = [MID]

    # This might be a bit slow, because of allocations, but a copy is slower, normal vec or sized vec is also slower
    placements_genereated = MVector{8,Bool}(false, false, false, false, false, false, false, false)

    # loop over all locations with tiles
    for (semi_tile, loc) in enumerate(board.tile_locs)
        # only generate moves for tiles of the current color 
        # != because the index is 1-based, tiles are 0-based
        if semi_tile % 2 != board.current_color
            # only generate moves for tiles that are placed
            if loc != INVALID_LOC
                if !all(placements_genereated) && loc == NOT_PLACED
                    # Generate placements for unplaced tiles that are the first of their kind
                    tile = get_tile_unplaced(semi_tile)
                    bug = get_tile_bug(tile)
                    if !placements_genereated[bug + 1] && bug != Integer(Bug.QUEEN)
                        generate_placements(board, my_placement_locs, tile)
                        placements_genereated[bug + 1] = true
                    end
                end
            end
        end
    end
    return nothing
end

"""
valid actions for second placement (first placement by black)
"""
function secondplacements(board)
    my_placement_locs = generate_placement_locs(board, 1)

    # This might be a bit slow, because of allocations, but a copy is slower, normal vec or sized vec is also slower
    placements_genereated = MVector{8,Bool}(false, false, false, false, false, false, false, false)

    # loop over all locations with tiles
    for (semi_tile, loc) in enumerate(board.tile_locs)
        # only generate moves for tiles of the current color 
        # != because the index is 1-based, tiles are 0-based
        if semi_tile % 2 != board.current_color
            # only generate moves for tiles that are placed
            if loc != INVALID_LOC
                if !all(placements_genereated) && loc == NOT_PLACED
                    # Generate placements for unplaced tiles that are the first of their kind
                    tile = get_tile_unplaced(semi_tile)
                    bug = get_tile_bug(tile)
                    if !placements_genereated[bug + 1] && bug != Integer(Bug.QUEEN)
                        generate_placements(board, my_placement_locs, tile)
                        placements_genereated[bug + 1] = true
                    end
                end
            end
        end
    end
    return nothing
end

function bugmoves(board, loc, bug, height, ispinned)
    if bug == Integer(Bug.ANT)
        antmoves(board, loc)
    elseif bug == Integer(Bug.SPIDER)
        spidermoves(board, loc)
    elseif bug == Integer(Bug.QUEEN)
        queenmoves(board, loc)
    elseif bug == Integer(Bug.BEETLE)
        beetlemoves(board, loc, height)
    elseif bug == Integer(Bug.GRASSHOPPER)
        grasshoppermoves(board, loc)
    elseif bug == Integer(Bug.LADYBUG)
        ladybugmoves(board, loc)
    elseif bug == Integer(Bug.MOSQUITO)
        mosquitomoves(board, loc, height, ispinned)
    elseif bug == Integer(Bug.PILLBUG)
        pillbugmoves(board, loc, ispinned)
    else
        error("Movement not implemented for bug $bug")
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
        bugmoves(board, loc, bug, height, ispinned)
    end
    return nothing
end

function pillbugmoves(board, startloc, ispinned)
    maxdepth = 1
    moves_to_depth(board, startloc, maxdepth)
    # Ladybug also has special moves
    # For all surrounding tiles, if they are not pinned, and did not just move,
    # and can slide on the pillbug, and the tile is not stacked
    # they can be slid on top of the pillbug, and then slid off
    neighlocs = allneighs(startloc)
    height = get_tile_height(get_tile_on_board(board, startloc))
    # For each neigh, see if it can slide high
    canslide = map(i -> canslidehigh(i, board, neighlocs, height), 1:6)
    slidelocs = map(i -> neighlocs[i], filter(i -> canslide[i], 1:6))
    foreach(
        i -> begin
            loc = neighlocs[i]
            for slideloc in slidelocs
                if get_tile_on_board(board, slideloc) == EMPTY_TILE
                    add_action(board, Move(loc, slideloc))
                end
            end
        end,
        filter(
            i -> begin
                loc = neighlocs[i]
                tile = get_tile_on_board(board, loc)
                return tile != EMPTY_TILE &&
                       !ispinned[loc] &&
                       loc != board.just_moved_loc &&
                       get_tile_height(tile) == 1 &&
                       canslide[i]
            end,
            1:6,
        ),
    )
    return nothing
end

function ladybugmoves(board, startloc)
    maxdepth = 3
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves = Set()
    moves_to_depth_ladybug!(board, startloc, maxdepth, moves)
    for move in moves
        add_action(board, move)
    end

    set_tile_on_board(board, startloc, tmp_tile)

    return nothing
end

function moves_to_depth_ladybug!(board, startloc, depth, moves, cur_loc=startloc)
    if depth == 0
        if cur_loc != startloc
            push!(moves, Move(startloc, cur_loc))
        end
        return nothing
    end
    neighlocs = allneighs(cur_loc)
    foreach(
        slideloc -> moves_to_depth_ladybug!(board, startloc, depth - 1, moves, slideloc),
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

function grasshoppermoves(board, startloc)
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
            add_action(board, Move(startloc, loc))
        end
    end
    return nothing
end

function beetlemoves(board, startloc, height)
    neighlocs = allneighs(startloc)
    if height != 1
        # Can go anywhere, so long as it can slide with height
        map(
            neigh -> begin
                add_action(board, Climb(startloc, neighlocs[neigh]))
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
                    add_action(board, Climb(startloc, neighlocs[neigh]))
                else
                    add_action(board, Move(startloc, neighlocs[neigh]))
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

function canslidehigh(i, board, neighlocs, height)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])
    goalheight = get_tile_height(get_tile_on_board(board, neighlocs[i]))

    return get_tile_height(neighleft) < max(goalheight + 1, height) ||
           get_tile_height(neighright) < max(goalheight + 1, height)
end

function queenmoves(board, startloc)
    maxdepth = 1
    moves_to_depth(board, startloc, maxdepth)
    return nothing
end

function spidermoves(board, startloc)
    maxdepth = 3
    moves_to_depth(board, startloc, maxdepth)
    return nothing
end

function antmoves(board, startloc)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)
    # Temporarily remove the tile to find where it can move to
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
            add_action(board, Move(startloc, goalloc))
        end
    end
    return nothing
end

function moves_to_depth(board, startloc, maxdepth)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves = Set()
    moves_to_depth!(board, startloc, maxdepth, moves)
    for move in moves
        add_action(board, move)
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
    foreach(
        slideloc -> begin
            if !discovered_dict[slideloc]
                push!(stack, slideloc)
                depth[slideloc] = depth[loc] + 1
            end
        end,
        map(
            i -> neighlocs[i],
            filter(i -> canslide(i, board, neighlocs) && !discovered_dict[neighlocs[i]], 1:6),
        ),
    )
end

@inline function canslide(i, board, neighlocs)
    return get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE && (
        (get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1]) == EMPTY_TILE) ⊻
        (get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1]) == EMPTY_TILE)
    )
end

function generate_placements(board, placement_locs, tile)
    foreach(loc -> add_action(board, Placement(loc, tile)), collect(placement_locs))
end

function generate_placement_locs(board, color)
    locs = Set{Int}()
    for loc in board.tile_locs
        if loc >= 0
            empty_neighs = filter(n -> get_tile_on_board(board, n) == EMPTY_TILE, allneighs(loc))

            for empty_neigh in empty_neighs
                neigh_locs2 = allneighs(empty_neigh)
                if all(
                    n ->
                        get_tile_on_board(board, n) == EMPTY_TILE ||
                            get_tile_color(get_tile_on_board(board, n)) == color,
                    neigh_locs2,
                )
                    push!(locs, empty_neigh)
                end
            end
        end
    end
    return locs
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
function get_pinned_tiles(board)
    pinned_tiles = DefaultDict(false)
    visited_dict = DefaultDict(false)
    depth_dict = Dict()
    low_dict = Dict()
    parent_dict = DefaultDict(INVALID_LOC)
    for loc in board.tile_locs
        if loc != INVALID_LOC && loc != NOT_PLACED
            get_pinned_tiles!(
                board, pinned_tiles, visited_dict, depth_dict, low_dict, parent_dict, loc, 0
            )
            return pinned_tiles
        end
    end
end

function get_pinned_tiles!(
    board, pinned_tiles_dict, visited_dict, depth_dict, low_dict, parent_dict, loc, depth
)
    visited_dict[loc] = true
    depth_dict[loc] = depth
    low_dict[loc] = depth
    child_count = 0
    is_articulation = false

    for nloc in allneighs(loc)
        if get_tile_on_board(board, nloc) == EMPTY_TILE
            continue
        end
        if !visited_dict[nloc]
            parent_dict[nloc] = loc
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
            if low_dict[nloc] >= depth_dict[loc]
                is_articulation = true
            end
            low_dict[loc] = min(low_dict[loc], low_dict[nloc])
        elseif nloc != parent_dict[loc]
            low_dict[loc] = min(low_dict[loc], depth_dict[nloc])
        end
    end
    if (parent_dict[loc] != INVALID_LOC && is_articulation) ||
        (parent_dict[loc] == INVALID_LOC && child_count > 1)
        pinned_tiles_dict[loc] = true
    end
end
