
function get_location_hash_value(loc)
    return get_hash_value(EMPTY_TILE, loc)
end

function get_hash_value(tile, loc; height=0)
    return HASH_VALUES[1 + (tile >> INDEX_SHIFT) + height * 36 + loc * 36 * 7]
end

function get_hash_value(board::Board)
    # add current_color and just_moved_loc to the hash, these can make the state different with equal pieces
    hash = board.hash
    if current_color == BLACK
        hash ⊻= COLOR_HASH
    end
    hash ⊻= JUST_MOVED_HASH_VALUES[just_moved_loc + 1]
    return hash
end

function get_location_hash_value(board::Board)
    # The location of the pieces is for determining sliding movement, no color or just moved loc matters
    return board.location_hash
end

const HASH_VALUES::Vector{UInt64} = rand(UInt64, 256 * 36 * 7) # 256 locations, 7 heights, 36 tiles (actually fewer but this makes the indexing easier)
const COLOR_HASH_VALUE::UInt64 = rand(UInt64)
const JUST_MOVED_HASH_VALUES::Vector{UInt64} = rand(UInt64, 257)
