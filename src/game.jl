function direction_from_string(tile_string::AbstractString)
    direction = filter(char -> !isletter(char) && !isdigit(char), tile_string)
    as_prefix = startswith(tile_string, direction)

    if as_prefix
        if direction == "\\"
            return Direction.NW
        elseif direction == "-"
            return Direction.W
        elseif direction == "/"
            return Direction.SW
        end
    else
        if direction == "\\"
            return Direction.SE
        elseif direction == "-"
            return Direction.E
        elseif direction == "/"
            return Direction.NE
        end
    end
    return nothing
end

function apply_direction(loc::Int, direction)::Int
    if direction == Direction.E
        return (loc + 1) % GRID_SIZE
    elseif direction == Direction.W
        return (loc - 1 + GRID_SIZE) % GRID_SIZE
    elseif direction == Direction.NW
        return (loc - 1 - ROW_SIZE + GRID_SIZE) % GRID_SIZE
    elseif direction == Direction.NE
        return (loc - ROW_SIZE + GRID_SIZE) % GRID_SIZE
    elseif direction == Direction.SE
        return (loc + 1 + ROW_SIZE) % GRID_SIZE
    elseif direction == Direction.SW
        return (loc + ROW_SIZE) % GRID_SIZE
    end
    return error("invalid direction $direction")
end

function get_tile_color(tile)
    return (tile & COLOR_MASK) >>> COLOR_SHIFT
end

function get_tile_bug(tile)
    return ((tile & BUG_MASK) >>> BUG_SHIFT) + 0x01
end

function get_tile_bug_num(tile)
    return (tile & BUG_NUM_MASK) >>> BUG_NUM_SHIFT
end

function get_tile_height(tile)
    if tile == EMPTY_TILE
        return 0x00
    end
    return ((tile & HEIGHT_MASK) >>> HEIGHT_SHIFT) + 0x01
end

@inline function get_tile_height_unsafe(tile)
    return ((tile & HEIGHT_MASK) >>> HEIGHT_SHIFT) + 0x01
end

function next_bug_num(tile)
    color, bug, bug_num, height = get_tile_info(tile)
    max_num = MAX_NUMS[bug]
    if bug_num == max_num
        return EMPTY_TILE
    end
    return tile_from_info(color, bug, bug_num + 0x01; height=height - 0x01)
end

"""
Return the color, bug, bug_num, and height of a tile
"""
function get_tile_info(tile)
    color = get_tile_color(tile)
    bug = get_tile_bug(tile)
    bug_num = get_tile_bug_num(tile)
    height = get_tile_height(tile)

    return color, bug, bug_num, height
end

@inline function tile_from_info(color, bug::UInt8, bug_num::UInt8; height::UInt8=0x00)
    return (
        color * (0b00000001 << COLOR_SHIFT) +
        (bug - 0x01) * (0b00000001 << BUG_SHIFT) +
        bug_num * (0b00000001 << BUG_NUM_SHIFT) +
        height * (0b00000001 << HEIGHT_SHIFT)
    )
end

@inline function tile_from_info_as_index(color, bug::UInt8, bug_num::UInt8)
    return (
        color * (0b00000001 << (COLOR_SHIFT - INDEX_SHIFT)) +
        (bug - 0x01) * (0b00000001 << (BUG_SHIFT - INDEX_SHIFT)) +
        bug_num * (0b00000001 << (BUG_NUM_SHIFT - INDEX_SHIFT))
    ) + 0x01
end

@inline function tile_from_info_as_index_odd(color, bug, bug_num)
    return (
        color * (0b00000001 << (COLOR_SHIFT - INDEX_SHIFT)) +
        (bug - 0x01) * (0b00000001 << (BUG_SHIFT - INDEX_SHIFT)) +
        bug_num * (0b00000001 << (BUG_NUM_SHIFT - INDEX_SHIFT))
    )
end

@inline function get_tile_unplaced(semi_tile::Int)
    tile_as_index = UInt8(semi_tile - 1)
    return tile_as_index << INDEX_SHIFT
end

@inline function get_tile_on_board(board::Board, loc::Int)
    # Loc is zero indexed
    return @fastmath @inbounds board.tiles[loc + 1]
end

@inline function set_tile_on_board(board::Board, loc::Int, tile::UInt8)
    # Loc is zero indexed
    @inbounds board.tiles[loc + 1] = tile
    return nothing
end

@inline function get_loc(board::Board, tile::UInt8)
    # Indexed by UInt8 >>> 2 (so a normal tile, withouth height info), zero indexed
    return @inbounds board.tile_locs[(tile >>> INDEX_SHIFT) + 1]
end

function set_loc(board::Board, tile::UInt8, loc::Int)
    # Indexed by UInt8 >>> 2 (so a normal tile, withouth height info), zero indexed
    @inbounds board.tile_locs[(tile >>> INDEX_SHIFT) + 1] = loc
    return nothing
end

function handle_newgame_command(gametype::Type{T}) where {T<:Gametype}
    tiles = ones(UInt8, GRID_SIZE) .* EMPTY_TILE
    # initialize tile_locs at index NOT_PLACED, indication they are not placed
    # indexed by tiles without height INVALID_LOC(UInt8 >>> 2) so size is 64, not all indices might be used.
    tile_locs = ones(Int, 36) .* NOT_PLACED
    for index_from_tile in 1:36
        shifted_tile = index_from_tile - 1
        if !isvalid_shifted_tile(shifted_tile)
            tile_locs[index_from_tile] = INVALID_LOC
        end
    end
    newboard = Board(tiles, tile_locs, gametype)
    return newboard

    error("starting new game.. not implemented")
end

function placement_filter(tile_list, exclude_list)
    map(tile -> begin
        if get_tile_bug(tile) ∉ exclude_list
            return tile
        else
            return EMPTY_TILE
        end
    end, tile_list)
end

function gametype_placeable_tiles_filter(::Type{MLPGame}, tile_list)
    return placement_filter(tile_list, ())
end
function gametype_placeable_tiles_filter(::Type{LPGame}, tile_list)
    return placement_filter(tile_list, (Integer(Bug.MOSQUITO)))
end
function gametype_placeable_tiles_filter(::Type{MPGame}, tile_list)
    return placement_filter(tile_list, (Integer(Bug.LADYBUG)))
end
function gametype_placeable_tiles_filter(::Type{MLGame}, tile_list)
    return placement_filter(tile_list, (Integer(Bug.PILLBUG)))
end
function gametype_placeable_tiles_filter(::Type{MGame}, tile_list)
    return placement_filter(tile_list, (Integer(Bug.PILLBUG), Integer(Bug.LADYBUG)))
end
function gametype_placeable_tiles_filter(::Type{LGame}, tile_list)
    return placement_filter(tile_list, (Integer(Bug.MOSQUITO), Integer(Bug.PILLBUG)))
end
function gametype_placeable_tiles_filter(::Type{PGame}, tile_list)
    return placement_filter(tile_list, (Integer(Bug.MOSQUITO), Integer(Bug.LADYBUG)))
end
function gametype_placeable_tiles_filter(::Type{BaseGame}, tile_list)
    return placement_filter(
        tile_list, (Integer(Bug.MOSQUITO), Integer(Bug.PILLBUG), Integer(Bug.LADYBUG))
    )
end

function isvalid_shifted_tile(shifted_tile)
    tile = shifted_tile << INDEX_SHIFT
    _, bug, bug_num, _ = get_tile_info(tile)
    if bug == Integer(Bug.QUEEN) ||
        bug == Integer(Bug.LADYBUG) ||
        bug == Integer(Bug.MOSQUITO) ||
        bug == Integer(Bug.PILLBUG)
        return bug_num == 0
    elseif bug == Integer(Bug.BEETLE) || bug == Integer(Bug.SPIDER)
        return bug_num <= 1
    elseif bug == Integer(Bug.GRASSHOPPER) || bug == Integer(Bug.ANT)
        return bug_num <= 2
    else
        error("Invalid bug $bug")
    end
end

"""
Given a tile string such as bB2, wL, return the tile as a UInt8
"""
function get_tile_from_string(board::Board, tile_string)
    tile_without_height = get_tile_from_string(tile_string)
    height = UInt8(length(board.underworld[get_loc(board, tile_without_height)]))
    return tile_without_height + height
end

function get_tile_from_string(tile_string)
    if tile_string == "empty"
        return EMPTY_TILE
    end
    white = tile_string[1] == 'w'
    if tile_string[2] == 'A'
        bug = Integer(Bug.ANT)
        num = parse(UInt8, tile_string[3])
    elseif tile_string[2] == 'B'
        bug = Integer(Bug.BEETLE)
        num = parse(UInt8, tile_string[3])
    elseif tile_string[2] == 'G'
        bug = Integer(Bug.GRASSHOPPER)
        num = parse(UInt8, tile_string[3])
    elseif tile_string[2] == 'Q'
        bug = Integer(Bug.QUEEN)
        num = UInt8(1)
    elseif tile_string[2] == 'S'
        bug = Integer(Bug.SPIDER)
        num = parse(UInt8, tile_string[3])
    elseif tile_string[2] == 'L'
        bug = Integer(Bug.LADYBUG)
        num = UInt8(1)
    elseif tile_string[2] == 'M'
        bug = Integer(Bug.MOSQUITO)
        num = UInt8(1)
    elseif tile_string[2] == 'P'
        bug = Integer(Bug.PILLBUG)
        num = UInt8(1)
    else
        error("Invalid tile string $tile_string")
    end
    num -= 0x01
    return tile_from_info(white, bug, num)
end

function action_from_move_string(board::Board, move_string)
    if move_string == "pass"
        return Pass()
    end
    move_string = strip(move_string)
    validate_move_string(move_string)

    if ' ' in move_string
        # either a move or a placement
        # parse input to be some actual action that can be executed
        moving_string, placement = split(move_string, " ")
        other_string = filter(char -> isletter(char) || isdigit(char), placement)
        moving_string = strip(moving_string)
        other_string = strip(other_string)

        direction = direction_from_string(placement)

        # Now from the names, construct the tiles UInt8
        moving_tile = get_tile_from_string(board, moving_string)
        other_tile = get_tile_from_string(board, other_string)

        moving_loc = get_loc(board, moving_tile)
        other_loc = get_loc(board, other_tile)

        if other_loc == NOT_PLACED
            error(
                "Processing movestring $move_string: the goal piece $other_string is not placed on the board",
            )
        elseif moving_loc == UNDERGROUND
            error(
                "Processing movestring $move_string: the moving piece is underground and cannot move.",
            )
        end

        goal_loc = other_loc
        if !isnothing(direction)
            goal_loc = apply_direction(other_loc, direction)
        end

        if moving_loc != NOT_PLACED
            if get_tile_on_board(board, goal_loc) != EMPTY_TILE || get_tile_height(moving_tile) > 1
                action = Climb(moving_loc, goal_loc)
            else
                action = Move(moving_loc, goal_loc)
            end
        else
            # Placement; bug has no location and thus is in hand
            action = Placement(goal_loc, moving_tile)
        end
    else
        # First move, place in middle 
        goal_loc = MID
        moving_tile = get_tile_from_string(board, move_string)
        action = Placement(goal_loc, moving_tile)
    end
    valid_actions = validactions(board)
    if !(action in valid_actions)
        error(
            "Invalid action: '$(move_string_from_action(board, action))' or '$action' not present in valid actions",
        )
    end
    board.action_index = 1
    return action
end

function move_string_from_action(board::Board, action::Climb)
    moving_tile = get_tile_on_board(board, action.moving_loc)
    if moving_tile == EMPTY_TILE
        error(
            "no tile to move at loc $(action.moving_loc) for climb from $(action.moving_loc) to $(action.goal_loc)",
        )
    end
    move_string = get_tile_name(moving_tile)
    # the tile might be moving on top of another piece, if so, the goal string is just that piece
    # Other wise use the default goal string for movement
    goal_tile = get_tile_on_board(board, action.goal_loc)
    if goal_tile != EMPTY_TILE
        move_string *= " " * get_tile_name(goal_tile)
    else
        move_string *= move_string_goal(board, action.goal_loc; moving_loc=action.moving_loc)
    end
end

function move_string_from_action(board::Board, action::Move)
    moving_tile = get_tile_on_board(board, action.moving_loc)
    if moving_tile == EMPTY_TILE
        error(
            "no tile to move at loc $(action.moving_loc) for move from $(action.moving_loc) to $(action.goal_loc)",
        )
    end
    move_string = get_tile_name(moving_tile)

    move_string *= move_string_goal(board, action.goal_loc; moving_loc=action.moving_loc)
    return move_string
end

function move_string_from_action(board::Board, action::Placement)
    move_string = get_tile_name(action.tile)
    move_string *= move_string_goal(board, action.goal_loc)
    return move_string
end

function move_string_from_action(board::Board, action::Pass)
    return "pass"
end

function move_string_goal(board::Board, goal_loc; moving_loc=INVALID_LOC)
    # Find an occupied neighbor of the goal_loc
    move_string = ""
    for dir in instances(Direction.T)
        loc = apply_direction(goal_loc, dir)
        if get_tile_on_board(board, loc) != EMPTY_TILE && loc != moving_loc
            goal_tile = get_tile_on_board(board, loc)
            # note, the dir is the direction from the goal_loc to the occupied neighbor
            # for the move_string, we want the direction from the occupied neighbor to the goal_loc
            if dir == Direction.SE
                return move_string * " \\" * get_tile_name(goal_tile)
            elseif dir == Direction.E
                return move_string * " -" * get_tile_name(goal_tile)
            elseif dir == Direction.NE
                return move_string * " /" * get_tile_name(goal_tile)
            elseif dir == Direction.NW
                return move_string * " " * get_tile_name(goal_tile) * "\\"
            elseif dir == Direction.W
                return move_string * " " * get_tile_name(goal_tile) * "-"
            elseif dir == Direction.SW
                return move_string * " " * get_tile_name(goal_tile) * "/"
            end
        end
    end
    if move_string == ""
        move_string = " adj moving loc"
    end
    return move_string
end

function update_gamestring(gamestring, board::Board)
    if board.gameover
        if board.victor == DRAW
            gamestring.gamestate = "Draw"
        elseif board.victor == WHITE
            gamestring.gamestate = "WhiteWins"
        elseif board.victor == BLACK
            gamestring.gamestate = "BlackWins"
        else
            error("Unknown victor $(board.victor)")
        end
    else
        gamestring.gamestate = "InProgress"
    end

    gamestring.movestrings = ""
    # Build movestrings from most recent move back to start move
    history_index_save = board.last_history_index
    for history_index in reverse(1:(board.last_history_index))
        action = ALL_ACTIONS[board.history[history_index]]
        undo(board)
        movestring = move_string_from_action(board, action)
        gamestring.movestrings = ";" * movestring * gamestring.movestrings
    end

    # Then redo all undone moves
    for history_index in 1:(history_index_save)
        action = ALL_ACTIONS[board.history[history_index]]
        do_action(board, action)
    end
    @assert board.last_history_index == history_index_save
    board.last_history_index = history_index_save

    gamestring.player =
        board.current_color == WHITE ? "White[$(board.turn)]" : "Black[$(board.turn)]"
    return nothing
end

function compute_all_neighs(loc)
    return (
        apply_direction(loc, Direction.NE),
        apply_direction(loc, Direction.E),
        apply_direction(loc, Direction.SE),
        apply_direction(loc, Direction.SW),
        apply_direction(loc, Direction.W),
        apply_direction(loc, Direction.NW),
    )
end

const ALL_ALL_NEIGHS::SVector{GRID_SIZE,Tuple{Int,Int,Int,Int,Int,Int}} = map(
    loc -> compute_all_neighs(loc), 0:(GRID_SIZE - 1)
)

@inline function allneighs(loc)
    return @inbounds view(ALL_ALL_NEIGHS, loc + 1)[1]
end

function do_action(board::Board, string::AbstractString)
    action = action_from_move_string(board, string)
    do_action(board, action)
    return nothing
end

function do_action(board::Board, action_as_index::Int)
    # board.last_moves_index += 1
    # if board.last_moves_index == length(board.last_moves) + 1
    #     board.last_moves_index = 1
    # end
    # board.last_moves[board.last_moves_index] = (action_as_index, :done)

    do_for_action(action_as_index, action -> do_action(board, action))
    return nothing
end

function do_action(board::Board, pass::Pass)
    pre_action_update(board, pass)
    post_action_update(board, pass)
    return nothing
end

function do_action(board::Board, placement::Placement)
    pre_action_update(board, placement)
    set_tile_on_board(board, placement.goal_loc, placement.tile)
    set_loc(board, placement.tile, placement.goal_loc)
    if get_tile_bug(placement.tile) == Integer(Bug.QUEEN)
        board.queen_placed[board.current_color + 1] = true
    end

    bug = get_tile_bug(placement.tile)
    board.placeable_tiles[board.current_color + 1][bug] = next_bug_num(placement.tile)

    post_action_update(board, placement)
    return nothing
end

function do_action(board::Board, move::Move)
    pre_action_update(board, move)
    moving_tile = get_tile_on_board(board, move.moving_loc)
    if moving_tile == EMPTY_TILE
        # println(ALL_ACTIONS[getindex.(board.last_moves, 1)])
        # println(getindex.(board.last_moves, 2))
        # println(board.last_moves_index)
        show(board; simple=true)
        error(
            "processing move $(move_string_from_action(board, move)); no tile to move at loc $(move.moving_loc)",
        )
    end
    set_tile_on_board(board, move.goal_loc, moving_tile)
    set_tile_on_board(board, move.moving_loc, EMPTY_TILE)
    set_loc(board, moving_tile, move.goal_loc)

    # show(board.black_pieces)
    post_action_update(board, move)
    # show(board.black_pieces)
    return nothing
end

function do_action(board::Board, climb::Climb)
    pre_action_update(board, climb)
    burrowed_tile = get_tile_on_board(board, climb.goal_loc)
    moving_tile = get_tile_on_board(board, climb.moving_loc)

    if burrowed_tile != EMPTY_TILE
        # put the burrowed tile in the underworld
        push!(board.underworld[climb.goal_loc], burrowed_tile)
        set_loc(board, burrowed_tile, UNDERGROUND)
    end
    if get_tile_height(moving_tile) > 0x01
        # Release the tile below moving_tile from the underworld
        released_tile = pop!(board.underworld[climb.moving_loc])
        set_tile_on_board(board, climb.moving_loc, released_tile)
        set_loc(board, released_tile, climb.moving_loc)
    else
        set_tile_on_board(board, climb.moving_loc, EMPTY_TILE)
    end

    # This assumes the doing has already happened
    old_height = get_tile_height_unsafe(moving_tile) - 0x01
    moving_tile += UInt8(length(board.underworld[climb.goal_loc])) - old_height

    set_tile_on_board(board, climb.goal_loc, moving_tile)
    set_loc(board, moving_tile, climb.goal_loc)

    post_action_update(board, climb)
    return nothing
end

function undo(board::Board)
    if board.last_history_index == 0
        error("no moves to undo")
    end
    last_action_index = board.history[board.last_history_index]
    board.last_history_index -= 1
    undo_action(board, last_action_index)
end

function count_color_on_board(board; color=BLACK, show=false)
    count = 0
    color_odd = color + 0x01
    for bug in 0x01:0x08
        if get_tile_bug_num(board.placeable_tiles[color_odd][bug]) != 0
            for num in @inbounds 0x00:MAX_NUMS[bug]
                semi_tile = tile_from_info_as_index_odd(color_odd, bug, num)
                @inbounds loc = board.tile_locs[semi_tile]

                if loc == NOT_PLACED
                    break
                end
                if loc == UNDERGROUND || loc == INVALID_LOC
                    continue
                end
                show && println("found (semi) piece $semi_tile at $loc")
                count += 1
            end
        end
    end
    return count
end

function undo_action(board::Board, action_as_index::Integer)
    # board.last_moves_index += 1
    # if board.last_moves_index == length(board.last_moves) + 1
    #     board.last_moves_index = 1
    # end
    # board.last_moves[board.last_moves_index] = (action_as_index, :undone)

    do_for_action(action_as_index, action -> undo_action(board, action))
    return nothing
end

function undo_action(board::Board, action::Placement)
    set_tile_on_board(board, action.goal_loc, EMPTY_TILE)

    if get_loc(board, action.tile) != action.goal_loc
        show(board; simple=true)
        error(
            "Err in undoing $action, get_loc(board, action.tile) != action.goal_loc, i.e. $(get_loc(board, action.tile)) != $(action.goal_loc)",
        )
    end

    set_loc(board, action.tile, NOT_PLACED)
    bug = get_tile_bug(action.tile)
    if bug == Integer(Bug.QUEEN)
        board.queen_placed[board.current_color == WHITE ? (BLACK + 1) : (WHITE + 1)] = false
    end

    inverse_post_action_update(board, action)

    board.placeable_tiles[board.current_color + 1][bug] = action.tile

    # inverse_update_placement_locs_goal(board, action.goal_loc)
    return nothing
end

function undo_action(board::Board, action::Move)
    moving_tile = get_tile_on_board(board, action.goal_loc)
    set_tile_on_board(board, action.goal_loc, EMPTY_TILE)
    set_tile_on_board(board, action.moving_loc, moving_tile)
    set_loc(board, moving_tile, action.moving_loc)

    inverse_post_action_update(board, action)

    # inverse_update_placement_locs_goal(board, action.goal_loc)
    # inverse_update_placement_locs_start(board, action.moving_loc)
    return nothing
end

function undo_action(board::Board, climb::Climb)
    burrowed_tile = get_tile_on_board(board, climb.moving_loc)
    moving_tile = get_tile_on_board(board, climb.goal_loc)

    if burrowed_tile != EMPTY_TILE
        # put the burrowed tile in the underworld
        push!(board.underworld[climb.moving_loc], burrowed_tile)
        set_loc(board, burrowed_tile, UNDERGROUND)
    end
    if get_tile_height_unsafe(moving_tile) > 0x01
        # Release the tile below moving_tile from the underworld
        released_tile = pop!(board.underworld[climb.goal_loc])
        set_tile_on_board(board, climb.goal_loc, released_tile)
        set_loc(board, released_tile, climb.goal_loc)
    else
        set_tile_on_board(board, climb.goal_loc, EMPTY_TILE)
    end

    # This assumes that the undoing has already happened
    old_height = get_tile_height_unsafe(moving_tile) - 0x01
    new_tile = moving_tile + UInt8(length(board.underworld[climb.moving_loc])) - old_height

    set_tile_on_board(board, climb.moving_loc, new_tile)
    set_loc(board, new_tile, climb.moving_loc)

    inverse_post_action_update(board, climb)

    return nothing
end

function undo_action(board::Board, pass::Pass)
    inverse_post_action_update(board, pass)
    return nothing
end

function inverse_post_action_update(board::Board, action)
    inverse_post_action_pillbug_update(board)
    inverse_post_action_general_update(board)

    # This assumes the color is already back at the color that made the change!!
    inverse_post_action_bb_update(board, action)

    goal_loc_normal, moving_loc_normal = get_last_changed_locs(action)
    # since we are trying to undo this move pas it as a move from goal -> moving loc
    # nothing looks strange but get pinned tiles expect goal loc first then moving loc

    get_pinned_tiles!(board, moving_loc_normal, goal_loc_normal; inverse=true)
    return nothing
end

function inverse_post_action_general_update(board::Board)
    board.ply -= 1
    if board.current_color == WHITE
        board.current_color = BLACK
        board.turn -= 1
    else
        board.current_color = WHITE
    end
    if board.gameover
        board.gameover = false
        board.victor = NO_COLOR
    end
    return nothing
end

function inverse_post_action_pillbug_update(board::Board)
    # Find the last move again (so one step deeper then undo)
    if !(board.last_history_index == 0)
        action_as_index = board.history[board.last_history_index]
        do_for_action(action_as_index, action -> post_action_pillbug_update(board, action))
    else
        board.just_moved_loc = INVALID_LOC
    end
    return nothing
end

function post_action_update(board::Board, action::Action)
    post_action_bb_update(board, action)
    post_action_pillbug_update(board, action)
    post_action_general_update(board, action)
    goal_loc, moving_loc = get_last_changed_locs(action)
    get_pinned_tiles!(board, goal_loc, moving_loc)
    return nothing
end

function post_action_pillbug_update(board::Board, move::Action)
    board.just_moved_loc = move.goal_loc
    return nothing
end

function pre_action_update(board::Board, action)
    board.last_history_index += 1
    board.history[board.last_history_index] = action_index(action)
    return nothing
end

function post_action_bb_update(board, placement::Placement)
    # This assumes the color is not yet changed!!
    goal_loc = placement.goal_loc
    place!(board, goal_loc)
end

function post_action_bb_update(board, action::Move)
    goal_loc = action.goal_loc
    color = get_tile_color(get_tile_on_board(board, goal_loc))
    place!(board, goal_loc; color=color)
    moving_loc = action.moving_loc
    remove!(board, moving_loc; color=color)
end

function post_action_bb_update(board, action::Climb)
    # This assumes the color is not yet changed!!
    opened_tile = get_tile_on_board(board, action.moving_loc)
    moved_tile = get_tile_on_board(board, action.goal_loc)

    remove!(board, action.moving_loc)
    if opened_tile != EMPTY_TILE
        color = get_tile_color(opened_tile)
        # This is like a $color tile was placed at the moving_loc
        place!(board, action.moving_loc; color=color)
    end

    if get_tile_height_unsafe(moved_tile) > 0x01
        covered_tile = first(board.underworld[action.goal_loc])
        color = get_tile_color(covered_tile)
        # This is like a $color tile was removed at the goal_loc
        remove!(board, action.goal_loc; color=color)
    end
    place!(board, action.goal_loc)
end

function post_action_bb_update(board, pass::Pass) end

function inverse_post_action_bb_update(board, placement::Placement)
    # This assumes the color is already back at the color that made the change!!
    goal_loc = placement.goal_loc
    remove!(board, placement.goal_loc)
    return nothing
end

function inverse_post_action_bb_update(board, action::Move)
    # This assumes the color is already back at the color that made the change!!
    goal_loc = action.goal_loc
    moving_loc = action.moving_loc
    color = get_tile_color(get_tile_on_board(board, moving_loc))

    remove!(board, goal_loc; color=color)
    place!(board, moving_loc; color=color)
    return nothing
end

function inverse_post_action_bb_update(board, action::Climb)
    # This assumes the color is already back at the color that made the change!!
    opened_tile = get_tile_on_board(board, action.goal_loc)
    moved_tile = get_tile_on_board(board, action.moving_loc)

    remove!(board, action.goal_loc)
    if opened_tile != EMPTY_TILE
        color = get_tile_color(opened_tile)
        # This is like a $color tile was placed at the goal_loc
        place!(board, action.goal_loc; color=color)
    end

    if get_tile_height_unsafe(moved_tile) > 0x01
        covered_tile = first(board.underworld[action.moving_loc])
        color = get_tile_color(covered_tile)
        # This is like a $color tile was removed at the moving_loc
        remove!(board, action.moving_loc; color=color)
    end
    place!(board, action.moving_loc)
    return nothing
end

function inverse_post_action_bb_update(board, pass::Pass) end

function post_action_general_update(board::Board, action)
    check_gameover(board)
    board.ply += 1
    if board.current_color == WHITE
        board.current_color = BLACK
    else
        board.turn += 1
        board.current_color = WHITE
    end
    return nothing
end

function check_gameover(board::Board)
    wQ = 0x24 # get_tile_from_string(board, "wQ")
    bQ = 0x20 # get_tile_from_string(board, "bQ")
    wQ_loc = get_loc(board, wQ)
    bQ_loc = get_loc(board, bQ)
    # Piece might be underground
    if wQ_loc == UNDERGROUND
        wQ_loc = find_underground_tile(board, wQ)
    end
    if bQ_loc == UNDERGROUND
        bQ_loc = find_underground_tile(board, bQ)
    end

    if wQ_loc >= 0 && all(loc -> get_tile_on_board(board, loc) != EMPTY_TILE, allneighs(wQ_loc))
        board.gameover = true
        board.victor = BLACK
    end
    if bQ_loc >= 0 && all(loc -> get_tile_on_board(board, loc) != EMPTY_TILE, allneighs(bQ_loc))
        if board.gameover
            board.victor = DRAW
        else
            board.gameover = true
            board.victor = WHITE
        end
    end
    return nothing
end

function find_underground_tile(board, tile)
    for (loc, stack) in board.underworld
        for other_tile in stack
            if other_tile >> INDEX_SHIFT == tile >> INDEX_SHIFT
                return loc
            end
        end
    end
    return -3
end

"""
Check if a command from the command line matches the format for a move, e.g. wG wA3\
"""
function validate_move_string(move_string)
    if ' ' in move_string
        # Move move_string
        moving_tile_string, placement = split(move_string, " ")
        goal_tile_string = filter(char -> isletter(char) || isdigit(char), placement)

        valid = validate_tile_string(moving_tile_string)
        valid &= validate_tile_string(goal_tile_string)
    else
        # single tile_string place move_string
        valid = validate_tile_string(move_string)
    end
    if !valid
        error("Invalid move string `$move_string`")
    end
    return nothing
end

function validate_tile_string(tile::AbstractString)
    # game type dependant
    if length(tile) >= 1 && tile[1] in "wb"
        if length(tile) == 2 && tile[2] in "QMLP"
            return true
        elseif tile[2] in "GA"
            return length(tile) == 3 && tile[3] in "123"
        elseif tile[2] in "SB"
            return length(tile) == 3 && tile[3] in "12"
        end
    end
    return false
end

function gametype_from_string(gametype_string)
    if gametype_string == "Base+MLP"
        return MLPGame
    elseif gametype_string == "Base+M"
        return MGame
    elseif gametype_string == "Base+P"
        return PGame
    elseif gametype_string == "Base+L"
        return LGame
    elseif gametype_string == "Base+ML"
        return MLGame
    elseif gametype_string == "Base+MP"
        return MPGame
    elseif gametype_string == "Base+LP"
        return LPGame
    elseif gametype_string == "Base+MLP"
        return MLPGame
    end
    error("game type '$gametype_string' not yet supported")
end

"""
Check if a move is not already in the valid actions
    
to avoid the pillbug adding duplicate moves
"""
function move_not_duplicate(board::Board, move, move_buffer)
    move_index = action_index(move)
    @inbounds buffer_view = view(move_buffer, 1:(board.action_index - 1))
    for action_index in buffer_view
        if action_index > MAX_PLACEMENT_INDEX && action_index == move_index
            return false
        end
    end
    return return true
end

"""
Some functionality for pre defining all actions to reduce allocations
"""

"""
The total number of idices = 256 ^ 2 + 256 ^ 2 + 256 * 36 = 140288 < 2^32
so we can use 32 bit integers as indices

when we save moves with goal index and tile we can get
256 * 36 + 256 * 36 + 256 * 36 = 27648 < 2^16 !
"""
# TODO speed: change to 16 bit ints. 
# TODO speed: when we separate placements, moves and climbs, we can use 16 bit integers as indices
# TODO func: the pass action is no longer handled probably. Fix this.
const MAX_PLACEMENT_INDEX = GRID_SIZE * 36
const MAX_MOVEMENT_INDEX = GRID_SIZE * GRID_SIZE
const MAX_CLIMB_INDEX = GRID_SIZE * GRID_SIZE
const MAX_PASS_INDEX = 1

@inline function action_index(placement::Placement)
    return placement_index(placement.goal_loc, placement.tile)
end

@inline function action_index(move::Move)
    return movement_index(move.moving_loc, move.goal_loc)
end

@inline function action_index(climb::Climb)
    return climb_index(climb.moving_loc, climb.goal_loc)
end

@inline function action_index(pass::Pass)
    return pass_index()
end

@inline function placement_index(loc::Int, tile::UInt8)
    return (tile >>> INDEX_SHIFT) * GRID_SIZE + loc + 1
end

const MOVEMENT_INDEX_OFFSET = MAX_PLACEMENT_INDEX + 1
@inline function movement_index(moving_loc::Int, goal_loc::Int)
    return @fastmath MOVEMENT_INDEX_OFFSET + moving_loc * GRID_SIZE + goal_loc
end

const CLIMB_INDEX_OFFSET = MAX_MOVEMENT_INDEX + MAX_PLACEMENT_INDEX + 1
@inline function climb_index(moving_loc::Int, goal_loc::Int)
    return @fastmath CLIMB_INDEX_OFFSET + moving_loc * GRID_SIZE + goal_loc
end

const PASS_INDEX_OFFSET = MAX_MOVEMENT_INDEX + MAX_PLACEMENT_INDEX + MAX_CLIMB_INDEX + 1

@inline function pass_index()
    return PASS_INDEX_OFFSET
end

function get_all_placements()
    all_placements = Vector{Placement}(undef, GRID_SIZE * 36)
    for loc in 0:(GRID_SIZE - 1)
        for bug in 0x01:0x08
            for num in 0x00:MAX_NUMS[bug]
                wtile = tile_from_info(WHITE, bug, num)
                btile = tile_from_info(BLACK, bug, num)
                all_placements[placement_index(loc, wtile)] = Placement(loc, wtile)
                all_placements[placement_index(loc, btile)] = Placement(loc, btile)
            end
        end
    end
    return all_placements
end

function get_all_movements()
    all_movements = Vector{Move}(undef, GRID_SIZE * GRID_SIZE)
    for moving_loc in 0:(GRID_SIZE - 1)
        for goal_loc in 0:(GRID_SIZE - 1)
            all_movements[movement_index(moving_loc, goal_loc) - MAX_PLACEMENT_INDEX] = Move(
                moving_loc, goal_loc
            )
        end
    end
    return all_movements
end

function get_all_climbs()
    all_climbs = Vector{Climb}(undef, GRID_SIZE * GRID_SIZE)
    for moving_loc in 0:(GRID_SIZE - 1)
        for goal_loc in 0:(GRID_SIZE - 1)
            all_climbs[climb_index(moving_loc, goal_loc) - MAX_MOVEMENT_INDEX - MAX_PLACEMENT_INDEX] = Climb(
                moving_loc, goal_loc
            )
        end
    end
    return all_climbs
end

function get_all_actions()
    all_actions = Vector{Action}(
        undef, MAX_PLACEMENT_INDEX + MAX_MOVEMENT_INDEX + MAX_CLIMB_INDEX + MAX_PASS_INDEX
    )
    all_placements = ALL_PLACEMENTS
    all_movements = ALL_MOVEMENTS
    all_climbs = ALL_CLIMBS
    all_actions[begin:MAX_PLACEMENT_INDEX] = all_placements
    all_actions[(MAX_PLACEMENT_INDEX + 1):(MAX_PLACEMENT_INDEX + MAX_MOVEMENT_INDEX)] =
        all_movements
    all_actions[(MAX_PLACEMENT_INDEX + MAX_MOVEMENT_INDEX + 1):(end - 1)] = all_climbs
    all_actions[end] = Pass()
    return all_actions
end

"""
This returns a union of types and as such is not the best, moves should be linked to
"""
function do_for_action(action_as_index, func)
    if action_as_index < MAX_PLACEMENT_INDEX
        action = ALL_PLACEMENTS[action_as_index]
        return func(action)
    elseif action_as_index < MAX_PLACEMENT_INDEX + MAX_MOVEMENT_INDEX
        action = ALL_MOVEMENTS[action_as_index - MAX_PLACEMENT_INDEX]
        return func(action)
    elseif action_as_index < MAX_PLACEMENT_INDEX + MAX_MOVEMENT_INDEX + MAX_CLIMB_INDEX
        action = ALL_CLIMBS[action_as_index - (MAX_PLACEMENT_INDEX + MAX_MOVEMENT_INDEX)]
        return func(action)
    else
        return func(Pass())
    end
end

const ALL_PLACEMENTS::Vector{Placement} = get_all_placements()
const ALL_MOVEMENTS::Vector{Move} = get_all_movements()
const ALL_CLIMBS::Vector{Climb} = get_all_climbs()
const ALL_ACTIONS::Vector{Action} = get_all_actions()
