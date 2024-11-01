
function Base.:&(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first & bb2.first, bb1.second & bb2.second)
end

function or(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first | bb2.first, bb1.second | bb2.second)
end

function inplace_or!(bb1::BitBoard, bb2::BitBoard)
    bb1.first |= bb2.first
    bb1.second |= bb2.second
    return nothing
end

function Base.:⊻(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(xor(bb1.first, bb2.first), xor(bb1.second, bb2.second))
end

@inline function isempty(bb::BitBoard)
    return bb.first | bb.second == UInt128(0)
end

function Base.:getindex(bb::BitBoard, loc)::Bool
    # Practical, but probably not the fastest
    if loc < 128
        return (bb.first & (UInt128(1) << loc)) != 0
    else
        return (bb.second & (UInt128(1) << (loc - 128))) != 0
    end
end

@inline function place!(board::Board, loc::Int64)
    if board.current_color == WHITE
        place!(board.white_pieces, loc)
        inplace_or!(board.white_adjacent, get_neigh_bb(loc))
    else
        place!(board.black_pieces, loc)
        inplace_or!(board.black_adjacent, get_neigh_bb(loc))
    end
end

@inline function remove!(board::Board, loc::Int64)
    if board.current_color == WHITE
        remove!(board.white_pieces, loc)
        update_adj!(board.white_adjacent, allneighs(loc), board.white_pieces)
    else
        remove!(board.black_pieces, loc)
        update_adj!(board.black_adjacent, allneighs(loc), board.black_pieces)
    end
end

@inline function update_adj!(adj_bb::BitBoard, neighs::Tuple{Int,Int,Int,Int,Int,Int}, pieces_bb)
    for i in 1:6
        loc = neighs[i]
        neigh_neigh_bb = get_neigh_bb(loc)
        # If this bb has no overlap with the pieces bb then the value at loc should be set to zero, otherwise keep it at 1. 
        remove_optional!(adj_bb, loc, isempty(neigh_neigh_bb & pieces_bb))
    end
end

@inline function place!(bb::BitBoard, loc::Int64)
    if loc < 128
        bb.first |= (UInt128(1) << loc)
    else
        bb.second |= (UInt128(1) << (loc - 128))
    end
    return nothing
end

@inline function remove!(bb::BitBoard, loc::Int64)
    if loc < 128
        bb.first ⊻= (UInt128(1) << loc)
    else
        bb.second ⊻= (UInt128(1) << (loc - 128))
    end
    return nothing
end

@inline function remove_optional!(bb::BitBoard, loc::Int64, do_remove)
    if loc < 128
        bb.first ⊻= ((UInt128(1) & do_remove) << loc)
    else
        bb.second ⊻= ((UInt128(1) & do_remove) << (loc - 128))
    end
    return nothing
end

function compute_neigh_bb(loc)
    neighs = allneighs(loc)
    first = UInt128(0)
    second = UInt128(0)
    for i in 1:6
        val = neighs[i]
        if val < 128
            first |= UInt128(1) << val
        else
            second |= UInt128(1) << (val - 128)
        end
    end
    return BitBoard(first, second)
end

const ALL_NEIGHS_BBS::SVector{GRID_SIZE,BitBoard} = map(
    loc -> compute_neigh_bb(loc), 0:(GRID_SIZE - 1)
)

@inline function get_neigh_bb(loc)
    return @inbounds view(ALL_NEIGHS_BBS, loc + 1)[1]
end
