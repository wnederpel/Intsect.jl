
function Base.:&(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first & bb2.first, bb1.second & bb2.second)
end

function Base.:|(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(bb1.first | bb2.first, bb1.second | bb2.second)
end

function Base.:xor(bb1::BitBoard, bb2::BitBoard)
    return BitBoard(xor(bb1.first, bb2.first), xor(bb1.second, bb2.second))
end

function place!(board::Board, loc::Int64)
    if board.current_color == WHITE
        place!(board.white_pieces, loc)
        place!(board.white_adjacent, allneighs(loc))
    else
        place!(board.black_pieces, loc)
        place!(board.black_adjacent, allneighs(loc))
    end
end

function place!(bb::BitBoard, neighs::Tuple{Int,Int,Int,Int,Int,Int})
    for i in 1:6
        place!(bb, neighs[i])
    end
end

function place!(bb::BitBoard, loc::Int64)
    if loc < 128
        bb.first |= (UInt128(1) << loc)
    else
        bb.second |= (UInt128(1) << (loc - 128))
    end
    return nothing
end