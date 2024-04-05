function validactions(board::Board)
    need_to_place_queen = !board.queen_placed[board.current_color + 1] && board.turn == 4
    first_placement = board.ply == 1
    second_placement = board.ply == 2
    (need_to_place_queen, first_placement, second_placement) |> println
    if need_to_place_queen
        return queenplacements(board)
    elseif first_placement
        return firstplacements(board)
    elseif second_placement
        return secondplacements(board)
    else
        return validactions_general(board)
    end
end

"""
Valid actions for the default case
"""
function validactions_general(board::Board)
    # TODO func: take just moved, moved by pillbug into account

    # TODO speed: maybe split in two functions, one for placement and one for moves, avoid queen placed checked for each tile, more same checks on all tiles can be extracted perhaps.  
    # TODO speed: be more carefull about the bugs for which movements should be generated
    # Once all bugs of type are placed no more placements should be generated for that bug

    # TODO func: queen must be placed by turn 4
    # TODO func: queen cannot be placed on first turn
    # TODO func: when game over, no moves can be made

    # TODO speed: ispinned does not need to be recomputed after every move
    # when an elbow is filled, or when a piece is simply pinnned, the dict only changes locally.
    ispinned = get_pinned_pieces(board)

    my_placement_locs = generate_placement_locs(board, board.current_color)

    valid_moves = []

    # This might be a bit slow, because of allocations, but a copy is slower, normal vec or sized vec is also slower
    placements_genereated = MVector{8,Bool}(false, false, false, false, false, false, false, false)

    # TODO speed: investigate custom interator that only interates over the right color (and perhaps more)
    # This loop pattern is repeated in the other validactions functions
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
                    if !placements_genereated[bug + 1]
                        valid_moves = [valid_moves; generate_placements(my_placement_locs, tile)]
                        placements_genereated[bug + 1] = true
                    end
                elseif board.queen_placed[board.current_color]
                    # Generate moves for placed tiles
                    tile = get_tile_on_board(board, loc)
                    if !ispinned[tile]
                        bug = get_tile_bug(tile)
                        valid_moves = [
                            valid_moves
                            bugmoves(board, loc, bug, get_tile_height(tile), ispinned)
                        ]
                    end
                end
            end
        end
    end
    return valid_moves
end

"""
valid actions for when the queen must be placed
"""
function queenplacements(board)
    my_placement_locs = generate_placement_locs(board, board.current_color)

    return generate_placements(
        my_placement_locs,
        board.current_color == WHITE ? get_tile_from_string("wQ") : get_tile_from_string("bQ"),
    )
end

"""
valid actions for when the first move is made
"""
function firstplacements(board)
    my_placement_locs = [MID]

    valid_moves = []

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
                        valid_moves = [valid_moves; generate_placements(my_placement_locs, tile)]
                        placements_genereated[bug + 1] = true
                    end
                end
            end
        end
    end
    return valid_moves
end

"""
valid actions for second placement (first placement by black)
"""
function secondplacements(board)
    my_placement_locs = generate_placement_locs(board, 1)

    valid_moves = []

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
                        valid_moves = [valid_moves; generate_placements(my_placement_locs, tile)]
                        placements_genereated[bug + 1] = true
                    end
                end
            end
        end
    end
    return valid_moves
end

function bugmoves(board, loc, bug, height, ispinned)
    if bug == Integer(Bug.ANT)
        return antmoves(board, loc)
    elseif bug == Integer(Bug.SPIDER)
        return spidermoves(board, loc)
    elseif bug == Integer(Bug.QUEEN)
        return queenmoves(board, loc)
    elseif bug == Integer(Bug.BEETLE)
        return beetlemoves(board, loc, height)
    elseif bug == Integer(Bug.GRASSHOPPER)
        return grasshoppermoves(board, loc)
    elseif bug == Integer(Bug.LADYBUG)
        return ladybugmoves(board, loc)
    elseif bug == Integer(Bug.MOSQUITO)
        return mosquitomoves(board, loc, height, ispinned)
    elseif bug == Integer(Bug.PILLBUG)
        return pillbugmoves(board, loc, ispinned)
    else
        error("Movement not implemented for bug $bug")
    end
end

function mosquitomoves(board, loc, height, ispinned)
    if height != 1
        return bugmoves(board, loc, Integer(Bug.BEETLE), height, ispinned)
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
    moves = []
    for bug in neighbugs
        moves = [moves; bugmoves(board, loc, bug, height, ispinned)]
    end
    return moves
end

function pillbugmoves(board, startloc, ispinned)
    maxdepth = 1
    normal_moves = moves_to_depth(board, startloc, maxdepth)
    # Ladybug also has special moves
    # For all surrounding tiles, if they are not pinned, and did not just move,
    # and can slide on the pillbug, and the piece is not stacked
    # they can be slid on top of the pillbug, and then slid off
    neighlocs = allneighs(startloc)
    height = get_tile_height(get_tile_on_board(board, startloc))
    # For each neigh, see if it can slide high
    canslide = map(i -> canslidehigh(i, board, neighlocs, height), 1:6)
    slidelocs = map(i -> neighlocs[i], filter(i -> canslide[i], 1:6))
    specialmoves = []
    foreach(
        i -> begin
            loc = neighlocs[i]
            for slideloc in slidelocs
                if get_tile_on_board(board, slideloc) == EMPTY_TILE
                    push!(specialmoves, Move(loc, slideloc))
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
    return [normal_moves; specialmoves]
end

function ladybugmoves(board, startloc)
    maxdepth = 3
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves = Set()
    moves_to_depth_ladybug!(board, startloc, maxdepth, moves)

    set_tile_on_board(board, startloc, tmp_tile)

    return collect(moves)
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
    return map(
        dir -> begin
            loc = startloc
            while true
                loc = apply_direction(loc, dir)
                tile = get_tile_on_board(board, loc)
                if tile == EMPTY_TILE
                    break
                end
            end
            return Move(startloc, loc)
        end,
        filter(
            dir -> begin
                loc = apply_direction(startloc, dir)
                return get_tile_on_board(board, loc) != EMPTY_TILE
            end, instances(Direction.T)
        ),
    )
end

function beetlemoves(board, startloc, height)
    neighlocs = allneighs(startloc)
    if height != 1
        # Can go anywhere, so long as it can slide with height
        return map(
            neigh -> begin
                if get_tile_on_board(board, neighlocs[neigh]) != EMPTY_TILE
                    return Climb(startloc, neighlocs[neigh])
                else
                    return Move(startloc, neighlocs[neigh])
                end
            end,
            filter(i -> canslidehigh(i, board, neighlocs, height), 1:6),
        )
    else
        # can go anywhere on top, or where it can slide
        tmp_tile = get_tile_on_board(board, startloc)
        set_tile_on_board(board, startloc, EMPTY_TILE)
        moves = map(
            neigh -> begin
                if get_tile_on_board(board, neighlocs[neigh]) != EMPTY_TILE
                    return Climb(startloc, neighlocs[neigh])
                else
                    return Move(startloc, neighlocs[neigh])
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
        return moves
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
    return moves_to_depth(board, startloc, maxdepth)
end

function spidermoves(board, startloc)
    maxdepth = 3
    return moves_to_depth(board, startloc, maxdepth)
end

function antmoves(board, startloc)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)
    # Temporarily remove the piece to find where it can move to
    discovered_dict = DefaultDict(false)
    stack = Stack{Int}()

    push!(stack, startloc)

    while !isempty(stack)
        loc = pop!(stack)
        push_slidelocs!(board, stack, loc, discovered_dict)
    end
    set_tile_on_board(board, startloc, tmp_tile)

    moves = []
    for (goalloc, discovered) in discovered_dict
        if discovered && goalloc != startloc
            push!(moves, Move(startloc, goalloc))
        end
    end
    return moves
end

function moves_to_depth(board, startloc, maxdepth)
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)

    moves = Set()
    moves_to_depth!(board, startloc, maxdepth, moves)

    set_tile_on_board(board, startloc, tmp_tile)

    return collect(moves)
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

function get_pinned_pieces(board)
    # TODO speed: implement
    return DefaultDict(false)
end

function generate_placements(placement_locs, tile)
    return map(loc -> Placement(loc, tile), collect(placement_locs))
end

function generate_placement_locs(board, color)
    locs = Set{Int}()
    for loc in board.tile_locs
        if loc >= 0
            neigh_locs = allneighs(loc)
            empty_neighs = filter(n -> get_tile_on_board(board, n) == EMPTY_TILE, neigh_locs)

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
