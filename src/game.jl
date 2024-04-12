
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
    return error(
        "char $direction_char is not a valid direction indicator, should be one of \\ - /."
    )
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
    return (tile & COLOR_MASK) >> COLOR_SHIFT
end

function get_tile_bug(tile)
    return (tile & BUG_MASK) >> BUG_SHIFT
end

function get_tile_bug_num(tile)
    return (tile & BUG_NUM_MASK) >> BUG_NUM_SHIFT
end

function get_tile_height(tile)
    if tile == EMPTY_TILE
        return 0x00
    end
    return (tile & HEIGHT_MASK) >> HEIGHT_SHIFT + 1
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

function get_tile_unplaced(loc::Int)
    tile_as_index = UInt8(loc - 1)
    return tile_as_index << INDEX_SHIFT
end

function get_tile_on_board(board::Board, loc::Int)
    # Loc is zero indexed
    return board.tiles[loc + 1]
end

function set_tile_on_board(board::Board, loc::Int, tile::UInt8)
    # Loc is zero indexed
    board.tiles[loc + 1] = tile
    return nothing
end

function get_loc(board, tile::UInt8)
    # Indexed by UInt8 >> 2 (so a normal tile, withouth height info), zero indexed
    return board.tile_locs[(tile >> INDEX_SHIFT) + 1]
end

function set_loc(board, tile::UInt8, loc::Int)
    # Indexed by UInt8 >> 2 (so a normal tile, withouth height info), zero indexed
    board.tile_locs[(tile >> INDEX_SHIFT) + 1] = loc
    return nothing
end

function handle_newgame_command(game_type)
    if game_type == Gametype.MLP
        tiles = ones(UInt8, GRID_SIZE) .* EMPTY_TILE
        # initialize tile_locs at index NOT_PLACED, indication they are not placed
        # indexed by tiles without height INVALID_LOC(UInt8 >> 2) so size is 64, not all indices might be used.
        tile_locs = ones(Int, 36) .* NOT_PLACED
        for index_from_tile in 1:36
            shifted_tile = index_from_tile - 1
            if !isvalid_shifted_tile(shifted_tile)
                tile_locs[index_from_tile] = INVALID_LOC
            end
        end
        newboard = Board(tiles, tile_locs)
        return newboard
    else
        return "game type $game_type unknown"
    end

    return "starting new game.. not implemented"
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
function get_tile_from_string(tile_string)
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
    return (
        (0b00000001 << COLOR_SHIFT) * white +
        (0b00000001 << BUG_SHIFT) * bug +
        (0b00000001 << BUG_NUM_SHIFT) * num
    )
end

function action_from_move_string(board, move_string)
    if move_string == "pass"
        return Pass()
    end
    validate_move_string(move_string)
    if ' ' in move_string
        # either a move or a placement
        # parse input to be some actual action that can be executed
        moving_string, placement = split(move_string, " ")
        other_string = filter(char -> isletter(char) || isdigit(char), placement)

        direction = direction_from_string(placement)

        # Now from the names, construct the tiles UInt8
        moving_tile = get_tile_from_string(moving_string)
        other_tile = get_tile_from_string(other_string)

        moving_loc = get_loc(board, moving_tile)
        other_loc = get_loc(board, other_tile)

        if other_loc == NOT_PLACED
            error("the goal piece $other_string is not placed on the board")
        end

        goal_loc = apply_direction(other_loc, direction)

        if moving_loc != NOT_PLACED
            # Move; bug has a INVALID_LOCcation
            action = Move(goal_loc, moving_loc)
        else
            # Placement; bug has no location and thus is in hand
            action = Placement(goal_loc, moving_tile)
        end
    else
        # First move, place in middle 
        goal_loc = MID
        moving_tile = get_tile_from_string(move_string)
        action = Placement(goal_loc, moving_tile)
    end
    if action in validactions(board)
        return action
    else
        error("Invalid action $action")
    end
    return action
end

function move_string_from_action(board, action::Move)
    moving_tile = get_tile_on_board(board, action.moving_loc)
    move_string = get_tile_name(moving_tile)

    move_string *= move_string_goal(board, action.goal_loc)
    return move_string
end

function move_string_from_action(board, action::Placement)
    move_string = get_tile_name(action.tile)
    move_string *= move_string_goal(board, action.goal_loc)
    return move_string
end

function move_string_from_action(board, action::Climb)
    error("move string from climb not implemented yet")
end

function move_string_from_action(board, action::Pass)
    return "pass"
end

function move_string_goal(board, goal_loc)
    # Find an occupied neighbor of the goal_loc
    move_string = ""
    for dir in instances(Direction.T)
        loc = apply_direction(goal_loc, dir)
        if get_tile_on_board(board, loc) != EMPTY_TILE
            goal_tile = get_tile_on_board(board, loc)
            if dir == Direction.NW
                return move_string * " \\" * get_tile_name(goal_tile)
            elseif dir == Direction.W
                return move_string * " -" * get_tile_name(goal_tile)
            elseif dir == Direction.SW
                return move_string * " /" * get_tile_name(goal_tile)
            elseif dir == Direction.SE
                return move_string * " " * get_tile_name(goal_tile) * "\\"
            elseif dir == Direction.E
                return move_string * " " * get_tile_name(goal_tile) * "-"
            elseif dir == Direction.NE
                return move_string * " " * get_tile_name(goal_tile) * "/"
            end
        end
    end
    return move_string
end

function update_gamestring(gamestring, board)
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
    for (_, movestring) in Iterators.reverse(board.history)
        gamestring.movestrings *= ";" * movestring
    end
    gamestring.player =
        board.current_color == WHITE ? "White[$(board.turn)]" : "Black[$(board.turn)]"
end

function allneighs(loc)
    # May be performance critical?
    return (
        apply_direction(loc, Direction.NE),
        apply_direction(loc, Direction.E),
        apply_direction(loc, Direction.SE),
        apply_direction(loc, Direction.SW),
        apply_direction(loc, Direction.W),
        apply_direction(loc, Direction.NW),
    )
end

function do_action(board, pass::Pass)
    post_action_update(board, pass)
end

function do_action(board, placement::Placement)
    set_tile_on_board(board, placement.goal_loc, placement.tile)
    set_loc(board, placement.tile, placement.goal_loc)
    if get_tile_bug(placement.tile) == Integer(Bug.QUEEN)
        board.queen_placed[board.current_color + 1] = true
    end

    post_action_update(board, placement)
end

function do_action(board, move::Move)
    moving_tile = get_tile_on_board(board, move.moving_loc)
    set_tile_on_board(board, move.goal_loc, moving_tile)
    set_tile_on_board(board, move.moving_loc, EMPTY_TILE)
    set_loc(board, moving_tile, move.goal_loc)

    post_action_update(board, move)
end

function do_action(board, move::Climb)
    # TODO func: add climb actions, and add underworld
    error("Do climb action not implemented yet.")

    post_action_update(board, move)
end

function undo(board)
    if isempty(board.history)
        error("no moves to undo")
    end
    last_action = pop!(board.history)[1]
    undo_action(board, last_action)
end

function undo_action(board, action::Placement)
    set_tile_on_board(board, action.goal_loc, EMPTY_TILE)
    set_loc(board, action.tile, NOT_PLACED)
    if get_tile_bug(action.tile) == Integer(Bug.QUEEN)
        board.queen_placed[board.current_color + 1] = false
    end

    inverse_post_action_update(board)
end

function inverse_post_action_update(board)
    inverse_post_action_pillbug_update(board)
    inverse_post_action_general_update(board)
end

function inverse_post_action_general_update(board)
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
end

function inverse_post_action_pillbug_update(board)
    if !isempty(board.history)
        last_action = first(board.history)[1]
        post_action_pillbug_update(board, last_action)
    else
        board.just_moved_loc = INVALID_LOC
        board.moved_by_pillbug_loc = INVALID_LOC
    end
end

function post_action_update(board, action::Union{Pass,Placement,Move,Climb})
    post_action_pillbug_update(board, action)
    post_action_general_update(board, action)
end

function post_action_pillbug_update(board, move)
    board.just_moved_loc = move.goal_loc
    # When the moving piece is of a different color then the current color, the pillbug has moved it
    if get_tile_color(get_tile_on_board(board, move.goal_loc)) != board.current_color
        board.moved_by_pillbug_loc = move.goal_loc
    else
        board.moved_by_pillbug_loc = INVALID_LOC
    end
end

function post_action_general_update(board, action)
    push!(board.history, (action, move_string_from_action(board, action)))
    check_gameover(board)
    if !board.gameover
        board.ply += 1
        if board.current_color == WHITE
            board.current_color = BLACK
        else
            board.turn += 1
            board.current_color = WHITE
        end
    end
end

function check_gameover(board)
    wQ = get_tile_from_string("wQ")
    bQ = get_tile_from_string("bQ")
    wQ_loc = get_loc(board, wQ)
    bQ_loc = get_loc(board, bQ)

    if all(loc -> get_tile_on_board(board, loc) != EMPTY_TILE, allneighs(wQ_loc))
        board.gameover = true
        board.victor = BLACK
    end
    if all(loc -> get_tile_on_board(board, loc) != EMPTY_TILE, allneighs(bQ_loc))
        if board.gameover
            board.victor = DRAW
        else
            board.gameover = true
            board.victor = WHITE
        end
    end
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
        valid &= !isempty(intersect(placement, raw"/\-"))
    else
        # single tile_string place move_string
        valid = validate_tile_string(move_string)
    end
    if !valid
        error("Invalid move string $move_string")
    end
end

function validate_tile_string(tile::AbstractString)
    # game type dependant
    if length(tile) >= 1 && tile[1] in "wb"
        if length(tile) >= 2 && tile[2] in "QMLP"
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
        return Gametype.MLP
    else
        return error("game type '$gametype_string' not yet supported")
    end
end
