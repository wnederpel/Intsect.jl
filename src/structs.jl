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

const HEX_SET_NUM_WORDS::Int = GRID_SIZE / 64 # (power of two)
const HEX_SET_SHIFT::Int = trailing_zeros(GRID_SIZE) - trailing_zeros(HEX_SET_NUM_WORDS) # Use the last bits for the word index
const HEX_SET_MASK::Int = 64 - 1 # use the first HEX_SET_SHIFT as index in the array
const HEX_SET_TYPE::Type = UInt64

struct HexSet
    table::MVector{HEX_SET_NUM_WORDS,HEX_SET_TYPE}
end

function HexSet()
    return HexSet(fill(0, HEX_SET_NUM_WORDS))
end

struct MoveStoreEntry
    location_hash::UInt64
    ant_reachable_bb::HexSet
end

function MoveStoreEntry()
    return MoveStoreEntry(NO_HASH, HexSet())
end

function get_move_store_size(move_store_size_mb)
    entry_size = sizeof(MoveStoreEntry)
    n = (move_store_size_mb * 1024 * 1024) ÷ entry_size
    n_pow2 = 1 << (floor(Int, log2(n)))
    return n_pow2
end

move_store_size_mb = 256
const MOVE_STORE_SIZE::Int = get_move_store_size(move_store_size_mb)
const MOVE_STORE_MASK::Int = MOVE_STORE_SIZE - 1

"""
Contains all information of the current board state

Tiles are represented by a UInt8:\n
bits 6-7: bug num (e.g. the 3 in 3rd ant, num = 0 -> 1st, num = 1 -> 2nd; to save on tile_loc size) \n
bits 3-5: Bug (follows enum) \n
bit 2: Color (1 is white) \n
bits 0-1: tile height; capped at 3, so 0 (floor), 1, 2, >= 3 \n\n
note: at lvl 3 there are at least 3 beetles (2 under + 1 on top), since there are 6 beetles in total, there cannot be 2 other towers to limit motion. For exact height the underworld can be checked.
see underworld for covered tiles. \n
All ones when node is empty (EMPTY_TILE). \n


Arguments

- `tiles::SVector{GRID_SIZE,UInt8}`: All tiles on the board and what is on them. Important! this is 0 indexed, do not directly access, only via get_tile / set_tile

- `tile_locs::MVector{36,Int}`: For each tile, store its tile index, NOT_PLACED (-1) for unplaced tiles, Indexed by UInt8 >> 2 (so a normal tile, without height info), size 2^6 INVALID_LOC 64
except we know that the highest number reached is by a wG3 (num comes first so is most Important) e.g. 0b100011 = 35 (+1 for zero), this is still higher then the true number of tiles, which is 28.
The 36 array is zero indexed, so again use get_loc / set_loc.
"""
mutable struct Board
    tiles::MVector{GRID_SIZE,UInt8}
    tile_locs::MVector{36,Int}
    just_moved_loc::Int
    current_color::UInt8
    queen_placed::MVector{2,Bool}
    ply::Int
    turn::Int
    gameover::Bool
    victor::Int
    history::MVector{HISTORY_BUFFER_SIZE,Int}
    last_history_index::Int
    underworld::DefaultDict{Int,Stack{UInt8}}
    validactions::MVector{VALID_BUFFER_SIZE,Int}
    action_index::Int
    placeable_tiles::SVector{2,MVector{8,UInt8}}
    ispinned::MVector{GRID_SIZE,Bool}
    pieces::SVector{2,HexSet}
    area::SVector{2,HexSet}
    last_moves::Vector
    last_moves_index::Int
    general_pinned_update_required::Bool
    queen_pos_white::Int
    queen_pos_black::Int
    hash::UInt64
    location_hash::UInt64
    move_store::Vector{MoveStoreEntry}
end

function Board(tiles, tile_locs, gametype)
    return Board(
        tiles,
        tile_locs,
        INVALID_LOC,
        WHITE,
        MVector{2,Bool}(false, false),
        1,
        1,
        false,
        NO_COLOR,
        MVector{HISTORY_BUFFER_SIZE,Int}(fill(0, HISTORY_BUFFER_SIZE)),
        0,
        DefaultDict{Int,Stack{UInt8}}(() -> Stack{UInt8}()),
        MVector{VALID_BUFFER_SIZE,Int}(fill(0, VALID_BUFFER_SIZE)),
        1,
        SVector{2,MVector{8,UInt8}}(
            MVector{8,UInt8}(
                gametype_placeable_tiles_filter(
                    gametype,
                    get_tile_from_string.(["bA1", "bG1", "bB1", "bS1", "bQ", "bL", "bP", "bM"]),
                ),
            ),
            MVector{8,UInt8}(
                gametype_placeable_tiles_filter(
                    gametype,
                    get_tile_from_string.(["wA1", "wG1", "wB1", "wS1", "wQ", "wL", "wP", "wM"]),
                ),
            ),
        ),
        MVector{GRID_SIZE,Bool}(fill(false, GRID_SIZE)),
        [HexSet(), HexSet()],
        [HexSet(), HexSet()],
        repeat([(-1, :pass)], 1000),
        0,
        false,
        -1,
        -1,
        UInt64(0),
        UInt64(0),
        Vector{MoveStoreEntry}(fill(MoveStoreEntry(), MOVE_STORE_SIZE)),
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
