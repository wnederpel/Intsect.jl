
function validmoves(board::Board)
    # TODO: take queen placement into account
    # See notepad for notes
    ispinned = get_pinned_pieces(board)
    # loop over all locations with tiles
    white_placement_locs = generate_placement_locs(board, 1)
    black_placement_locs = generate_placement_locs(board, 0)
    valid_moves = []
    for loc in board.tile_locs
        if loc != INVALID_LOC
            if loc != NOT_PLACED
                tile = get_tile_unplaced(loc)
                my_placement_locs =
                    get_tile_color(tile) == WHITE ? white_placement_locs : black_placement_locs
                valid_moves = [valid_moves; generate_placements(my_placement_locs, tile)]
            else
                tile = get_tile_on_board(board, loc)
                if !ispinned[tile]
                    bug = get_tile_bug(tile)
                    if bug == Bug.ANT
                        valid_moves = [valid_moves; antmoves(board, loc)]
                    elseif bug == Bug.SPIDER
                        valid_moves = [valid_moves; spidermoves(board, loc)]
                    elseif bug == Bug.QUEEN
                        valid_moves = [valid_moves; queenmoves(board, loc)]
                    elseif bug == Bug.BEETLE
                        valid_moves = [valid_moves; beetlemoves(board, loc, get_tile_height(tile))]
                    elseif bug == Bug.GRASSHOPPER
                        valid_moves = [valid_moves; grasshoppermoves(board, loc)]
                    elseif bug == Bug.LADYBUG
                        valid_moves = [valid_moves; ladybugmoves(board, loc)]
                    else
                        error("Movement not implemented for bug $bug")
                    end
                end
            end
        end
    end
end

function ladybugmoves(board, startloc)
    maxdepth = 3
    tmp_tile = get_tile_on_board(board, startloc)
    set_tile_on_board(board, startloc, EMPTY_TILE)
    # Temporarily remove the piece to find where it can move to
    discovered_dict = DefaultDict(false)
    depth = Dict()
    stack = Stack{Int}()

    push!(stack, startloc)
    depth[startloc] = 0

    while !isempty(stack)
        loc = pop!(stack)
        discovered_dict[loc] = true
        if depth[loc] < maxdepth
            neighlocs = allneighs(loc)
            foreach(
                slideloc -> begin
                    println("loc = $loc, slideloc = $slideloc, depth = $(depth[loc])")
                    depth[slideloc] = depth[loc] + 1
                    push!(stack, slideloc)
                end,
                map(
                    i -> neighlocs[i],
                    filter(
                        i -> begin
                            if depth[loc] == 0
                                # Move up
                                return get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                                       canslideheigh(i, board, neighlocs, 0)
                            elseif depth[loc] == 1
                                # Move on hive
                                return get_tile_on_board(board, neighlocs[i]) != EMPTY_TILE &&
                                       canslideheigh(
                                    i,
                                    board,
                                    neighlocs,
                                    get_tile_height(get_tile_on_board(board, loc)),
                                )
                            elseif depth[loc] == 2
                                # Move down
                                return get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE &&
                                       canslideheigh(
                                    i,
                                    board,
                                    neighlocs,
                                    get_tile_height(get_tile_on_board(board, loc)),
                                )
                            else
                                return false
                            end
                        end,
                        1:6,
                    ),
                ),
            )
        end
    end

    set_tile_on_board(board, startloc, tmp_tile)

    moves = []
    for (goalloc, discovered) in discovered_dict
        if depth[goalloc] == 3 && discovered && goalloc != startloc
            push!(moves, Move(startloc, goalloc))
        end
    end
    return moves
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
    if height != 0
        # Can go anywhere, so long as it can slide with height
        return map(
            neigh -> begin
                if get_tile_on_board(board, neighlocs[neigh]) != EMPTY_TILE
                    return Climb(startloc, neighlocs[neigh])
                else
                    Move(startloc, neighlocs[neigh])
                end
            end,
            filter(i -> canslideheigh(i, board, neighlocs, height), 1:6),
        )
        # return map(neigh -> Climb(startloc, neighlocs[neigh]), valid_neighs)
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
                        canslideheigh(i, board, neighlocs, 0)
                    ) || canslide(i, board, neighlocs),
                1:6,
            ),
        )
        set_tile_on_board(board, startloc, tmp_tile)
        return moves
    end
end

function canslideheigh(i, board, neighlocs, height)
    neighleft = get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1])
    neighright = get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1])
    return neighleft == EMPTY_TILE ||
           neighright == EMPTY_TILE ||
           get_tile_height(neighleft) < (height + 1) ||
           get_tile_height(neighright) < (height + 1)
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
        if !discovered_dict[loc]
            discovered_dict[loc] = true
            push_slidelocs!(board, stack, loc)
        end
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
    # Temporarily remove the piece to find where it can move to
    discovered_dict = DefaultDict(false)
    depth = Dict()
    stack = Stack{Int}()

    push!(stack, startloc)
    depth[startloc] = 0

    while !isempty(stack)
        loc = pop!(stack)
        discovered_dict[loc] = true
        if depth[loc] < maxdepth
            push_slidelocs!(board, stack, depth, discovered_dict, loc)
        end
    end
    set_tile_on_board(board, startloc, tmp_tile)

    moves = []
    for (goalloc, discovered) in discovered_dict
        if depth[goalloc] == maxdepth && discovered && goalloc != startloc
            push!(moves, Move(startloc, goalloc))
        end
    end
    return moves
end

"""
From the current position, one can travel in a direcion when:

 1. the direction itself is not filled
 2. one of the two neighbouring directions is filled
"""
function push_slidelocs!(board::Board, stack::Stack, loc)
    neighlocs = allneighs(loc)
    foreach(
        slideloc -> push!(stack, slideloc),
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
    return Dict()
end

function generate_placements(placement_locs, tile)
    return map(loc -> Placement(loc, tile), placement_locs)
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
