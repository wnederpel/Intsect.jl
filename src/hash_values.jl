
function get_location_hash_value(loc)
    return get_hash_value(EMPTY_TILE, loc)
end

function get_hash_value(tile, loc; height=0)
    # TODO, more info should be added here, like the piece that was moved last, the color to play, etc.
    # It's also better to make this a table of 7 * 36 * 256 = ~65k entries
    # Look into transposition tables -> Make a vector of ~ 256 mb entries, and use the hash % size as index.

    return HASH_VALUES[1 + (tile >> INDEX_SHIFT) + height * 36 + loc * 36 * 7]
end

const HASH_VALUES::Vector{UInt64} = rand(UInt64, 256 * 36 * 7) # 256 locations, 7 heights, 36 tiles (actually fewer but this makes the indexing easier)
