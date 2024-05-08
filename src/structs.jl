abstract type Action end

struct Move <: Action
    moving_loc::Int
    goal_loc::Int
end

struct Placement <: Action
    goal_loc::Int
    tile::UInt8
end

struct Climb <: Action
    moving_loc::Int
    goal_loc::Int
end

struct Pass <: Action
    # All actions have a goal loc
    goal_loc::Int
end

function Pass()
    return Pass(INVALID_LOC)
end

function Base.sizeof(::Type{Action})
    return 2 * sizeof(Int)
end

# TODO speed: Maybe convert to abstract arrays
"""
We use buffers to compute the valid actions, this can help avoid allocations
To save the buffers this struct is used. Initialize only with already computed valid actions.
Bumber unfortunatly does not like it when the arrays are a part of the struct, they are have to be seperate when filled
"""
struct ValidActions
    placements::SizedVector{VALID_BUFFER_SIZE,Placement}
    placement_index::Integer
    moves::SizedVector{VALID_BUFFER_SIZE,Move}
    move_index::Integer
    clibs::SizedVector{VALID_BUFFER_SIZE,Climb}
    climb_index::Integer
    can_pass::Bool
end

# continue with using the new valid actions approach, the iteration over valid actions needs to be changed

"""
because the board needs to be initialized with something
"""
function ValidActions()
    return ValidActions(
        SizedVector{VALID_BUFFER_SIZE,Placement}(undef),
        1,
        SizedVector{VALID_BUFFER_SIZE,Move}(undef),
        1,
        SizedVector{VALID_BUFFER_SIZE,Climb}(undef),
        1,
        false,
    )
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


Arguments

- `tiles::SVector{GRID_SIZE,UInt8}`: All tiles on the board and what is on them. Important! this is 0 indexed, do not directly access, only via get_tile / set_tile

- `tile_locs::MVector{36,Int}`: For each tile, store its tile index, NOT_PLACED (-1) for unplaced tiles, Indexed by UInt8 >> 2 (so a normal tile, withouth height info), size 2^6 INVALID_LOC 64
except we know that the highest number reached is by a wG3 (num comes first so is most Important) e.g. 0b100011 = 35 (+1 for zero), this is still higher then the true number of tiles, which is 28.
The 36 array is zero indexed, so again use get_loc / set_loc.
"""
# TODO speed: maybe the locs can be UInt8's too, although julia indexing works with integers
# TODO speed: custom types can be used for tiles for clarity and maybe speed? at least avoids type instability
mutable struct Board
    # TODO speed: Think about making 2 seperate structs, the tiles & tile_locs vectors struct can be static 
    tiles::MVector{GRID_SIZE,UInt8}
    # TODO speed: Do not use the 36 entries with invalid locs, but instead use a predefined indexing of tiles
    tile_locs::MVector{36,Int}
    just_moved_loc::Int
    moved_by_pillbug_loc::Int
    current_color::Integer
    queen_placed::MVector{2,Bool}
    ply::Int
    turn::Int
    gameover::Bool
    victor::Int
    history::Stack{Action}
    underworld::DefaultDict{Int,Stack{UInt8}}
    validactions::ValidActions
    placeable_tiles::SVector{2,MVector{8,UInt8}}
    placement_locs::SVector{2,BitSet}
end

function Board(tiles, tile_locs)
    return Board(
        tiles,
        tile_locs,
        INVALID_LOC,
        INVALID_LOC,
        WHITE,
        MVector{2,Bool}(false, false),
        1,
        1,
        false,
        NO_COLOR,
        Stack{Action}(),
        DefaultDict{Int,Stack{UInt8}}(() -> Stack{UInt8}()),
        ValidActions(),
        SVector{2,MVector{8,UInt8}}(
            MVector{8,UInt8}(
                get_tile_from_string.(["bA1", "bG1", "bB1", "bS1", "bQ", "bL", "bM", "bP"])
            ),
            MVector{8,UInt8}(
                get_tile_from_string.(["wA1", "wG1", "wB1", "wS1", "wQ", "wL", "wM", "wP"])
            ),
        ),
        SVector{2,Set}(BitSet(), BitSet()),
    )
end

mutable struct GameString
    gametype::String
    gamestate::String
    player::String
    movestrings::String
end

function GameString()
    return GameString("Base+MLP", "NotStarted", "White[1]", "")
end

function GameString(board)
    gamestring = GameString()
    update_gamestring(gamestring, board)
    return gamestring
end
