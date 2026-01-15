@inline function Base.:&(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.x1 & bb2.x1, bb1.x2 & bb2.x2, bb1.x3 & bb2.x3, bb1.x4 & bb2.x4)
end

@inline function Base.:|(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.x1 | bb2.x1, bb1.x2 | bb2.x2, bb1.x3 | bb2.x3, bb1.x4 | bb2.x4)
end

@inline function Base.:~(bb1::BitBoard)
    return BitBoard(~bb1.x1, ~bb1.x2, ~bb1.x3, ~bb1.x4)
end

# ---- helpers: limb math ----
@inline _limb(loc::Integer) = (loc >>> 6) + 1
@inline _bit(loc::Integer) = UInt64(1) << (loc & 63)

import Base: ==

function ==(bb1::BitBoard, bb2::BitBoard)
    return bb1.x1 == bb2.x1 && bb1.x2 == bb2.x2 && bb1.x3 == bb2.x3 && bb1.x4 == bb2.x4
end

@inline function Base.:>>>(bb::BitBoard, n::Integer)
    x4 = bb.x4 >>> n
    x3 = bb.x3 >>> n | (bb.x4 << (64 - n))
    x2 = bb.x2 >>> n | (bb.x3 << (64 - n))
    x1 = bb.x1 >>> n | (bb.x2 << (64 - n))
    return BitBoard(x1, x2, x3, x4)
end

@inline function Base.:<<(bb::BitBoard, n::Integer)
    x4 = bb.x4 << n | (bb.x3 >>> (64 - n))
    x3 = bb.x3 << n | (bb.x2 >>> (64 - n))
    x2 = bb.x2 << n | (bb.x1 >>> (64 - n))
    x1 = bb.x1 << n
    return BitBoard(x1, x2, x3, x4)
end

function Base.copy(bb::BitBoard)
    return BitBoard(bb.x1, bb.x2, bb.x3, bb.x4)
end

@inline function Base.bitrotate(bb::BitBoard, n::Integer)
    if n > 0
        x4 = bb.x4 << n | (bb.x3 >>> (64 - n))
        x3 = bb.x3 << n | (bb.x2 >>> (64 - n))
        x2 = bb.x2 << n | (bb.x1 >>> (64 - n))
        x1 = bb.x1 << n | (bb.x4 >>> (64 - n))
    elseif n < 0
        n = -n
        x1 = bb.x1 >>> n | (bb.x2 << (64 - n))
        x2 = bb.x2 >>> n | (bb.x3 << (64 - n))
        x3 = bb.x3 >>> n | (bb.x4 << (64 - n))
        x4 = bb.x4 >>> n | (bb.x1 << (64 - n))
    else
        return bb
    end

    return BitBoard(x1, x2, x3, x4)
end

@inline function get_adjacent_bb(bb::BitBoard)
    return bb |
           bitrotate(bb, 1) |
           bitrotate(bb, -1) |
           bitrotate(bb, ROW_SIZE) |
           bitrotate(bb, -ROW_SIZE) |
           bitrotate(bb, ROW_SIZE + 1) |
           bitrotate(bb, -ROW_SIZE - 1)
end

@inline function fill_placement_locs_bb(board)
    white_adjacent = get_adjacent_bb(board.white_pieces)
    black_adjacent = get_adjacent_bb(board.black_pieces)
    occ = board.white_pieces | board.black_pieces
    if board.current_color == WHITE
        return (white_adjacent) & ~(black_adjacent | occ)
    else
        return (black_adjacent) & ~(white_adjacent | occ)
    end
end

@inline function Base.:⊻(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(
        xor(bb1.x1, bb2.x1), xor(bb1.x2, bb2.x2), xor(bb1.x3, bb2.x3), xor(bb1.x4, bb2.x4)
    )
end

@inline function get_and_remove_first_loc(bb::BitBoard)
    # We have to & the bb with a special bb
    if bb.x1 != 0
        first_loc = trailing_zeros(bb.x1)
        return first_loc, BitBoard(bb.x1 & (bb.x1 - 1), bb.x2, bb.x3, bb.x4)
    elseif bb.x2 != 0
        first_loc = trailing_zeros(bb.x2)
        return first_loc + 64, BitBoard(bb.x1, bb.x2 & (bb.x2 - 1), bb.x3, bb.x4)
    elseif bb.x3 != 0
        first_loc = trailing_zeros(bb.x3)
        return first_loc + 128, BitBoard(bb.x1, bb.x2, bb.x3 & (bb.x3 - 1), bb.x4)
    elseif bb.x4 != 0
        first_loc = trailing_zeros(bb.x4)
        return first_loc + 192, BitBoard(bb.x1, bb.x2, bb.x3, bb.x4 & (bb.x4 - 1))
    end

    return INVALID_LOC, bb
end

@inline function get_first_loc(bb::BitBoard)
    # We have to & the bb with a special bb
    if bb.x1 != 0
        return trailing_zeros(bb.x1)
    elseif bb.x2 != 0
        return trailing_zeros(bb.x2) + 64
    elseif bb.x3 != 0
        return trailing_zeros(bb.x3) + 128
    elseif bb.x4 != 0
        return trailing_zeros(bb.x4) + 192
    end
    return INVALID_LOC
end

@inline function Base.count_ones(bb::BitBoard)
    return count_ones(bb.x1) + count_ones(bb.x2) + count_ones(bb.x3) + count_ones(bb.x4)
end

@inline function isempty(bb::BitBoard)
    return bb.x1 == 0 && bb.x2 == 0 && bb.x3 == 0 && bb.x4 == 0
end

@inline Base.@propagate_inbounds function Base.:getindex(bb::BitBoard, loc)::Bool
    limb = _limb(loc)
    m = _bit(loc)
    if limb == 1
        return (bb.x1 & m) != 0
    elseif limb == 2
        return (bb.x2 & m) != 0
    elseif limb == 3
        return (bb.x3 & m) != 0
    else
        return (bb.x4 & m) != 0
    end
end

function tile_at_loc(bb::BitBoard, loc)::Bool
    # Practical, but probably not the fastest
    return bb[loc]
end

# Note: place and remove should both be doable with just an xor
@inline function toggle!(board::Board, loc; color::Number=2)
    if color == 2
        color = board.current_color
    end
    if color == WHITE
        board.white_pieces = toggle(board.white_pieces, loc)
    else
        board.black_pieces = toggle(board.black_pieces, loc)
    end
    return nothing
end

@inline function toggle(bb::BitBoard, loc)
    limb = _limb(loc)
    m = _bit(loc)
    limb == 1 && return BitBoard(xor(bb.x1, m), bb.x2, bb.x3, bb.x4)
    limb == 2 && return BitBoard(bb.x1, xor(bb.x2, m), bb.x3, bb.x4)
    limb == 3 && return BitBoard(bb.x1, bb.x2, xor(bb.x3, m), bb.x4)
    return BitBoard(bb.x1, bb.x2, bb.x3, xor(bb.x4, m))
end

function compute_neigh_bb(loc)
    neighs = allneighs(loc)
    bb = BitBoard()
    for i in 1:6
        bb |= get_bb(neighs[i])
    end
    return bb
end

function compute_bb_val(loc)
    if loc < 64
        return UInt64(1) << loc
    elseif loc < 128
        return UInt64(1) << (loc - 64)
    elseif loc < 192
        return UInt64(1) << (loc - 128)
    else
        return UInt64(1) << (loc - 192)
    end
end

function compute_bb(loc)
    if loc < 64
        return BitBoard(UInt64(1) << loc, 0, 0, 0)
    elseif loc < 128
        return BitBoard(0, UInt64(1) << (loc - 64), 0, 0)
    elseif loc < 192
        return BitBoard(0, 0, UInt64(1) << (loc - 128), 0)
    else
        return BitBoard(0, 0, 0, UInt64(1) << (loc - 192))
    end
end

@inline function get_bb_val(loc)
    return @inbounds ALL_BB_VALS[loc + 1]
end

@inline function get_bb(loc)
    return @inbounds ALL_BB[loc + 1]
end

@inline function get_neigh_bb(loc)
    return @inbounds ALL_NEIGHS_BBS[loc + 1]
end

const ALL_BB_VALS::SVector{GRID_SIZE,UInt64} = map(loc -> compute_bb_val(loc), 0:(GRID_SIZE - 1))

const ALL_BB::SVector{GRID_SIZE,BitBoard} = map(loc -> compute_bb(loc), 0:(GRID_SIZE - 1))

const ALL_NEIGHS_BBS::SVector{GRID_SIZE,BitBoard} = map(
    loc -> compute_neigh_bb(loc), 0:(GRID_SIZE - 1)
)
