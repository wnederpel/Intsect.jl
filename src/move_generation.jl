
function validmoves(board::Board)
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
                    else
                        error("movement generation not implemented for bug $bug")
                    end
                end
            end
        end
    end
end

function slide_moves_to_depth(board, startloc, maxdepth)
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
        if !discovered_dict[loc] && depth[loc] < maxdepth
            discovered_dict[loc] = true
            push_slidelocs!(board, stack, depth, loc)
        end
    end
    set_tile_on_board(board, startloc, tmp_tile)

    moves = []
    for (goalloc, discovered) in discovered_dict
        if discovered && goalloc != startloc
            push!(moves, Move(goalloc, startloc))
        end
    end
    return moves
end

function spidermoves(board, startloc)
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
        if !discovered_dict[loc]
            discovered_dict[loc] = true
            if depth[loc] < maxdepth
                push_slidelocs!(board, stack, depth, discovered_dict, loc)
            end
        end
    end
    set_tile_on_board(board, startloc, tmp_tile)

    moves = []
    for (goalloc, discovered) in discovered_dict
        if depth[goalloc] == maxdepth && discovered && goalloc != startloc
            push!(moves, Move(goalloc, startloc))
        end
    end
    return moves
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
            push!(moves, Move(goalloc, startloc))
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
        map(
            i -> neighlocs[i],
            filter(
                i ->
                    get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE && (
                        (get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1]) == EMPTY_TILE) ⊻
                        (get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1]) == EMPTY_TILE)
                    ),
                1:6,
            ),
        ),
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
            filter(
                i ->
                    get_tile_on_board(board, neighlocs[i]) == EMPTY_TILE && (
                        (get_tile_on_board(board, neighlocs[i == 1 ? 6 : i - 1]) == EMPTY_TILE) ⊻
                        (get_tile_on_board(board, neighlocs[i == 6 ? 1 : i + 1]) == EMPTY_TILE)
                    ),
                1:6,
            ),
        ),
    )
end

function get_pinned_pieces(board)
    return Dict()
end

function generate_placements(placement_locs, tile)
    return map(loc -> Placement(tile, loc), placement_locs)
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
