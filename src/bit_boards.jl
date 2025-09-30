@inline function Base.:&(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first & bb2.first, bb1.second & bb2.second)
end

@inline function Base.:|(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first | bb2.first, bb1.second | bb2.second)
end

@inline function Base.:~(bb1::BitBoard)
    return BitBoard(~bb1.first, ~bb1.second)
end

import Base: ==

function ==(bb1::BitBoard, bb2::BitBoard)
    return bb1.first == bb2.first && bb1.second == bb2.second
end

@inline function Base.:>>>(bb::BitBoard, n::Integer)
    second = bb.second >>> n
    first = bb.first >>> n | (bb.second << (128 - n))
    return BitBoard(first, second)
end

@inline function Base.:<<(bb::BitBoard, n::Integer)
    first = bb.first << n
    second = bb.second << n | (bb.first >>> (128 - n))
    return BitBoard(first, second)
end

function Base.copy(bb::BitBoard)
    return BitBoard(bb.first, bb.second)
end

@inline function Base.bitrotate(x::T, k::Integer) where {T}
    return (x << ((sizeof(T) << 3 - 1) & k)) | (x >>> ((sizeof(T) << 3 - 1) & -k))
end

function get_adjacent_bb(bb::BitBoard)
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
    if board.current_color == WHITE
        return (white_adjacent) & ~(black_adjacent | board.black_pieces | board.white_pieces)
    else
        return (black_adjacent) & ~(white_adjacent | board.black_pieces | board.white_pieces)
    end
end

@inline function Base.:⊻(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(xor(bb1.first, bb2.first), xor(bb1.second, bb2.second))
end

@inline function get_and_remove_first_loc(bb::BitBoard)
    # We have to & the bb with a special bb
    if bb.first != UInt128(0)
        first_loc = trailing_zeros(bb.first)
        bb &= BitBoard(bb.first - 1, bb.second)
        return first_loc, bb
    elseif bb.second != UInt128(0)
        first_loc = trailing_zeros(bb.second)
        bb &= BitBoard(bb.first, bb.second - 1)
        return first_loc + 128, bb
    end
    return INVALID_LOC, bb
end

@inline function get_first_loc(bb::BitBoard)
    # We have to & the bb with a special bb
    if bb.first != UInt128(0)
        return trailing_zeros(bb.first)
    elseif bb.second != UInt128(0)
        return trailing_zeros(bb.second) + 128
    end
    return INVALID_LOC
end

@inline function Base.count_ones(bb::BitBoard)
    return count_ones(bb.first) + count_ones(bb.second)
end

@inline function isempty(bb::BitBoard)
    return bb.first == UInt128(0) && bb.second == UInt128(0)
end

function Base.:getindex(bb::BitBoard, loc)::Bool
    # Practical, but probably not the fastest
    if loc < 128
        return (bb.first & get_bb_val(loc)) != 0
    else
        return (bb.second & get_bb_val(loc)) != 0
    end
end

function tile_at_loc(bb::BitBoard, loc)::Bool
    # Practical, but probably not the fastest
    return bb[loc]
end

# Note: place and remove should both be doable with just an xor
@inline function toggle!(board::Board, loc::Int64; color::Number=2)
    if color == 2
        color = board.current_color
    end
    loc_bb = get_bb(loc)
    if color == WHITE
        board.white_pieces ⊻= loc_bb
    else
        board.black_pieces ⊻= loc_bb
    end
    return nothing
end

@inline function toggle(bb::BitBoard, loc::Int64)
    bb ⊻= get_bb(loc)
    return bb
end

function compute_neigh_bb(loc)
    neighs = allneighs(loc)
    bb = BitBoard(0, 0)
    for i in 1:6
        bb |= get_bb(neighs[i])
    end
    return bb
end

@inline function get_neigh_bb(loc)
    return @inbounds view(ALL_NEIGHS_BBS, loc + 1)[1]
end

function compute_bb_val(loc)
    if loc < 128
        return UInt128(1) << loc
    else
        return UInt128(1) << (loc - 128)
    end
end

function compute_bb(loc)
    if loc < 128
        return BitBoard(UInt128(1) << loc, 0)
    else
        return BitBoard(0, UInt128(1) << (loc - 128))
    end
end

@inline function get_bb_val(loc)
    return @inbounds view(ALL_BB_VALS, loc + 1)[1]
end

@inline function get_bb(loc)
    return @inbounds view(ALL_BB, loc + 1)[1]
end

const ALL_BB_VALS::SVector{GRID_SIZE,UInt128} = map(loc -> compute_bb_val(loc), 0:(GRID_SIZE - 1))

const ALL_BB::SVector{GRID_SIZE,BitBoard} = map(loc -> compute_bb(loc), 0:(GRID_SIZE - 1))

const ALL_NEIGHS_BBS::SVector{GRID_SIZE,BitBoard} = map(
    loc -> compute_neigh_bb(loc), 0:(GRID_SIZE - 1)
)
