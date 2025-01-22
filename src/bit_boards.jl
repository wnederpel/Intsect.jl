
@inline function Base.:&(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first & bb2.first, bb1.second & bb2.second)
end

@inline function Base.:|(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first | bb2.first, bb1.second | bb2.second)
end

@inline function Base.:~(bb1::BitBoard)
    return BitBoard(~bb1.first, ~bb1.second)
end

@inline function fill_placement_locs_bb!(placement_locs_bb, board, color)
    if color == WHITE
        placement_locs_bb.first |= board.white_adjacent.first
        placement_locs_bb.second |= board.white_adjacent.second
        placement_locs_bb.first &=
            ~(board.black_adjacent.first | board.black_pieces.first | board.white_pieces.first)
        placement_locs_bb.second &=
            ~(board.black_adjacent.second | board.black_pieces.second | board.white_pieces.second)
    else
        placement_locs_bb.first |= board.black_adjacent.first
        placement_locs_bb.second |= board.black_adjacent.second
        placement_locs_bb.first &=
            ~(board.white_adjacent.first | board.black_pieces.first | board.white_pieces.first)
        placement_locs_bb.second &=
            ~(board.white_adjacent.second | board.black_pieces.second | board.white_pieces.second)
    end
end

@inline function inplace_or!(bb1::BitBoard, bb2::BitBoard)
    bb1.first |= bb2.first
    bb1.second |= bb2.second
    return nothing
end

@inline function inplace_xor!(bb1::BitBoard, bb2::BitBoard)
    bb1.first ⊻= bb2.first
    bb1.second ⊻= bb2.second
    return nothing
end

@inline function inplace_and!(bb1::BitBoard, bb2::BitBoard)
    bb1.first &= bb2.first
    bb1.second &= bb2.second
    return nothing
end

@inline function Base.:⊻(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(xor(bb1.first, bb2.first), xor(bb1.second, bb2.second))
end

@inline function remove_first_loc!(bb::BitBoard)
    # We have to & the bb with a special bb
    if bb.first != UInt128(0)
        # First loc is in first
        only_first_loc = bb.first & (~bb.first + 1)
        # Now remove this first loc from the bb and return 
        bb.first &= ~only_first_loc
        return true
    elseif bb.second != UInt128(0)
        # First loc is in second
        only_first_loc = bb.second & (~bb.second + 1)
        # Now remove this first loc from the bb and return 
        bb.second &= ~only_first_loc
        return true
    end
    return false
end

@inline function get_and_remove_first_loc!(bb::BitBoard)
    # We have to & the bb with a special bb
    if bb.first != UInt128(0)
        first_loc = trailing_zeros(bb.first)
        bb.first &= bb.first - 1
        return first_loc
    elseif bb.second != UInt128(0)
        first_loc = trailing_zeros(bb.second)
        bb.second &= bb.second - 1
        return first_loc + 128
    end
    return INVALID_LOC
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

@inline function place!(board::Board, loc::Int64; color::Number=2)
    if color == 2
        color = board.current_color
    end
    if color == WHITE
        place!(board.white_pieces, loc)
        inplace_or!(board.white_adjacent, get_neigh_bb(loc))
        return nothing
    else
        place!(board.black_pieces, loc)
        inplace_or!(board.black_adjacent, get_neigh_bb(loc))
        return nothing
    end
end

@inline function remove!(board::Board, loc::Int64; color::Number=2)
    if color == 2
        color = board.current_color
    end
    if color == WHITE
        remove!(board.white_pieces, loc)
        remove_adj!(board.white_adjacent, loc, board.white_pieces)
    else
        remove!(board.black_pieces, loc)
        remove_adj!(board.black_adjacent, loc, board.black_pieces)
    end
end

@inline function remove_adj!(adj_bb::BitBoard, loc::Int, pieces_bb)
    # TODO speed: The adjacent pieces bb can probably be quickly calculated from the pieces bb with bitshifts.
    for neigh in allneighs(loc)
        neigh_neigh_bb = get_neigh_bb(neigh)
        # If this bb has no overlap with the pieces bb then the value at neigh should be set to zero, otherwise keep it at 1. 
        if neigh_neigh_bb.first & pieces_bb.first == 0 &&
            neigh_neigh_bb.second & pieces_bb.second == 0
            remove!(adj_bb, neigh)
        end
    end
end

@inline function place!(bb::BitBoard, loc::Int64)
    inplace_or!(bb, get_bb(loc))
    return nothing
end

@inline function remove!(bb::BitBoard, loc::Int64)
    if loc < 128
        bb.first ⊻= get_bb_val(loc)
    else
        bb.second ⊻= get_bb_val(loc)
    end
    return nothing
end

@inline function remove_optional!(bb::BitBoard, loc::Int64, do_remove)
    if do_remove
        remove!(bb, loc)
    end
    return nothing
end

function compute_neigh_bb(loc)
    neighs = allneighs(loc)
    bb = BitBoard(0, 0)
    for i in 1:6
        bb |= bb_val[neighs[i]]
    end
    return bb
end

const ALL_NEIGHS_BBS::SVector{GRID_SIZE,BitBoard} = map(
    loc -> compute_neigh_bb(loc), 0:(GRID_SIZE - 1)
)

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

const ALL_BB_VALS::SVector{GRID_SIZE,UInt128} = map(loc -> compute_bb_val(loc), 0:(GRID_SIZE - 1))

const ALL_BB::SVector{GRID_SIZE,BitBoard} = map(loc -> compute_bb(loc), 0:(GRID_SIZE - 1))

@inline function get_bb_val(loc)
    return @inbounds view(ALL_BB_VALS, loc + 1)[1]
end

@inline function get_bb(loc)
    return @inbounds view(ALL_BB, loc + 1)[1]
end