@enumx Gametype begin
    MLP
end

@enumx Bug::UInt8 begin
    ANT = 0         # 3
    GRASSHOPPER = 1 # 3
    BEETLE = 2      # 2
    SPIDER = 3      # 2
    QUEEN = 4       # 1
    LADYBUG = 5     # 1
    MOSQUITO = 6    # 1
    PILLBUG = 7     # 1
end

@enumx Direction::UInt8 begin
    NW
    NE
    E
    SE
    SW
    W
end

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

# Board representation: wrapping grid of tile locations.
# Rows wrap around, and each row wraps to the next row.
# It's like a spiral around a torus.

# A 4x4 example: NOTE 4x4, not 16x16

#         11  12  13  14  15
#           \ / \ / \ / \ /
#       15 - 0 - 1 - 2 - 3 - 4
#         \ / \ / \ / \ / \
#      3 - 4 - 5 - 6 - 7 - 8
#       \ / \ / \ / \ / \
#    7 - 8 - 9 -10 -11 -12
#     \ / \ / \ / \ / \
# 11 -12 -13 -14 -15 - 0
#     / \ / \ / \ / \
#    0   1   2   3   4
# Even the 16 x 16 might be way too small. 
# Each side as 14 pieces, so everything in a straight line would require
# 28 * 28 = 784 pieces.
const ROW_SIZE::Int = 5
const GRID_SIZE::Int = ROW_SIZE * ROW_SIZE

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

"""
Contains all information of the current board state

Tiles are represented by a UInt8:\n
bits 6-7: bug num (e.g. the 3 in 3rd ant, num = 0 -> 1st, num = 1 -> 2nd; to save on tile_loc size) \n
bits 3-5: Bug (folows enum) \n
bit 2: Color (1 is white) \n
bits 0-1: tile height; capped at 3, so 0 (floor), 1, 2, >= 3 \n\n
note: at lvl 3 there are at least 3 beetles (2 under + 1 on top), since there are 6 beetles in total, there cannot be 2 other towers to limit motion. For exact height the underworld can be checked.
see underworld for covered tiles. \n
All ones when node is empty (EMPTY_TILE). \n

TODO: add underworld

TODO: since the tiles are UInt8's, we can probably make everything UInt8's. At least the locs can be UInt8's, and the bugs too.

Arguments

  - `tiles::SVector{GRID_SIZE,UInt8}`: All tiles on the board and what is on them. Important! this is 0 indexed, do not directly access, only via get_tile / set_tile

  - `tile_locs::SizedVector{14,2,Int}`: For each tile, store its tile index, NOT_PLACED (-1) for unplaced tiles, Indexed by UInt8 >> 2 (so a normal tile, withouth height info), size 2^6 INVALID_LOC 64
    except we know that the highest number reached is by a wG3 (num comes first so is most Important) e.g. 0b100011 = 35 (+1 for zero), this is still higher then the true number of tiles, which is 28.
    The 36 array is zero indexed, so again use get_loc / set_loc.
"""
struct Board
    tiles::SizedVector{GRID_SIZE,UInt8}
    tile_locs::SizedVector{36,Int}
end

const BUG_NUM_MASK::UInt8 = 0b11000000
const BUG_NUM_SHIFT::UInt8 = 6
const BUG_MASK::UInt8 = 0b00111000
const BUG_SHIFT::UInt8 = 3
const COLOR_MASK::UInt8 = 0b00000100
const COLOR_SHIFT::UInt8 = 2
const HEIGHT_MASK::UInt8 = 0b00000011
const HEIGHT_SHIFT::UInt8 = 0

const INDEX_SHIFT::UInt8 = 2
const EMPTY_TILE::UInt8 = 0b11111111
const NOT_PLACED::Int = -1
const INVALID_LOC::Int = -2

const WHITE::Int = 1

function slides(bug)
    slides == Integer(IntBug.ANT) && return true
    slides == Integer(IntBug.BEETLE) && return true
    slides == Integer(IntBug.SPIDER) && return true
    slides == Integer(IntBug.QUEEN) && return true
    slides == Integer(IntBug.PILLBUG) && return true
    return false
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
    return (tile & HEIGHT_MASK) >> HEIGHT_SHIFT
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

function get_tile_on_board(board, loc::Int)
    # Loc is zero indexed
    return board.tiles[loc + 1]
end

function set_tile_on_board(board, loc::Int, tile::UInt8)
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

struct Move
    goal_loc::Int
    moving_loc::Int
end

struct Placement
    goal_loc::Int
    tile::UInt8
end

struct Climb
    goal_loc::Int
    moving_loc::Int
end

struct Pass end

# For now these are global constants, later make this configurable if that's interesting
const BUGS_IN_PLAY::Int = 8
const TOTAL_NUM_BUGS::Int = 14
const GAMETYPE::Gametype.T = Gametype.MLP

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
        board = Board(tiles, tile_locs)
        return board
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
        goal_loc = (ROW_SIZE + 1) * floor(ROW_SIZE / 2)
        moving_tile = get_tile_from_string(move_string)
        action = Placement(goal_loc, moving_tile)
    end
    return action
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

function do_action(board, pass::Pass) end

function do_action(board, placement::Placement)
    set_tile_on_board(board, placement.goal_loc, placement.tile)
    set_loc(board, placement.tile, placement.goal_loc)
end

function do_action(board, move::Move)
    moving_tile = get_tile_on_board(board, move.moving_loc)
    set_tile_on_board(board, move.goal_loc, moving_tile)
    set_tile_on_board(board, move.moving_loc, EMPTY_TILE)
    set_loc(board, moving_tile, move.goal_loc)
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
    if tile[1] in "wb"
        if tile[2] in "QMLP"
            return true
        elseif tile[2] in "GA"
            return tile[3] in "123"
        elseif tile[2] in "SB"
            return tile[3] in "12"
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
