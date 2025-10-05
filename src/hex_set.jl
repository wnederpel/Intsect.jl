@inline function loc_to_index_bit(loc::Integer)
    idx = (loc >>> HEX_SET_SHIFT) + 1
    bit = 1 << (loc & HEX_SET_MASK)
    return idx, bit
end

@inline function remove!(hs::HexSet, loc::Integer)
    idx, bit = loc_to_index_bit(loc)
    @inbounds hs.table[idx] &= ~bit
    return nothing
end

@inline function set!(hs::HexSet, loc::Integer)
    idx, bit = loc_to_index_bit(loc)
    @inbounds hs.table[idx] |= bit
    return nothing
end

@inline function toggle!(hs::HexSet, loc::Integer)
    idx, bit = loc_to_index_bit(loc)
    @inbounds hs.table[idx] ⊻= bit
    return nothing
end

@inline function get(hs::HexSet, loc::Integer)::Bool
    idx, bit = loc_to_index_bit(loc)
    @inbounds return (hs.table[idx] & bit) != 0
end

@inline function clear!(hs::HexSet)
    return fill!(hs.table, zero(HEX_SET_TYPE))
end

@inline function for_each_bit_set(f::Function, hs::HexSet)
    for i in 1:HEX_SET_NUM_WORDS
        @inbounds word = hs.table[i]
        while word != 0
            b = trailing_zeros(word)
            word &= word - 1
            index = (i - 1) * 64 + b
            f(index)
        end
    end
    return nothing
end

@inline function Base.count_ones(hs::HexSet)
    s = 0
    for word in hs.table
        s += Base.count_ones(word)
    end
    return s
end

function Base.:getindex(hs::HexSet, loc)
    return get(hs, loc)
end

function Base.copy(hs::HexSet)
    return HexSet(Base.copy(hs.table))
end

import Base.==

function ==(hs1::HexSet, hs2::HexSet)
    return hs1.table == hs2.table
end

function remove_tile_on_hex_set!(board, color_of_tile, loc)
    remove!(board.pieces[color_of_tile], loc)
    return nothing
end

function toggle_tile_on_hex_set!(board, color_of_tile, loc)
    toggle!(board.pieces[color_of_tile], loc)
    return nothing
end

function place_tile_on_hex_set!(board, color_of_tile, loc)
    set!(board.pieces[color_of_tile], loc)
    return nothing
end
