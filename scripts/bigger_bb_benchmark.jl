using BenchmarkTools, Random, Intsect, StaticArrays, FixedSizeArrays

# Assume BitBoard and the functions from your module are loaded.
const BOARD_BITS::Int = 64 * fieldcount(BitBoard)

const HEXSET_NUM_WORDS::Int = 9
const HEXSET_MASK::Int = HEXSET_NUM_WORDS - 1
const HEXSET_SHIFT::Int = 6  # 2^6 = 64 bits per word
const HEXSET_TYPE = UInt64  # or Int, depending on HEXSET_NUM_WORDS

struct HexSet
    table::MVector{HEXSET_NUM_WORDS,HEXSET_TYPE}
end

function HexSet()
    return HexSet(fill(0, HEXSET_NUM_WORDS))
end

function rand_bitboard()
    BitBoard(rand(UInt64), rand(UInt64), rand(UInt64), rand(UInt64))
end

function rand_hexset()
    rand_data = rand(HEXSET_TYPE, HEXSET_NUM_WORDS)
    hs = HexSet(rand_data)
    return hs
end

function set!(hs::HexSet, hex::Int)
    idx = hex & HEXSET_MASK
    bit = 1 << (hex >>> HEXSET_SHIFT)  # logical shift
    hs.table[idx + 1] |= bit   # Julia arrays are 1-based
    return nothing
end

function get(hs::HexSet, hex::Int)::Bool
    idx = hex & HEXSET_MASK
    bit = 1 << (hex >>> HEXSET_SHIFT)
    return (hs.table[idx + 1] & bit) != 0
end

function drain(hs::HexSet)
    s = 0
    for word in hs.table
        w = word
        while w != 0
            b = trailing_zeros(w)
            s += b          # consume result so LLVM can't drop the loop
            w &= w - 1     # clear the lowest set bit
        end
    end
    return s
end

function count_ones(hs::HexSet)
    s = 0
    for word in hs.table
        s += Base.count_ones(word)
    end
    return s
end

function Intsect.toggle(hs::HexSet, hex::Int)
    set!(hs, hex)
end

# Drain by repeatedly calling get_and_remove_first_loc until empty.
@inline function drain(bb::BitBoard)
    s = 0
    while true
        loc, bb = get_and_remove_first_loc(bb)
        if loc == INVALID_LOC
            break
        end
        s += loc          # consume result so LLVM can't drop the loop
    end
    return s
end

@inline function Base.bitrotate(hs::HexSet, n::Integer)
    nw = length(hs.table)
    totalbits = 64 * nw
    n = mod(n, totalbits)        # normalize to [0,totalbits)
    n == 0 && return hs

    wordshift, bitshift = divrem(n, 64)
    newwords = Vector{UInt64}(undef, nw)

    for i in 1:nw
        # source word index, wrapping around
        src = ((i - 1 - wordshift) % nw) + 1
        prev = ((src - 2) % nw) + 1  # word before src

        if bitshift == 0
            newwords[i] = hs.table[src]
        else
            newwords[i] = (hs.table[src] << bitshift) | (hs.table[prev] >>> (64 - bitshift))
        end
    end

    return HexSet(newwords)
end

@inline function get_adjacent_hs(hs::HexSet)
    return hs |
           bitrotate(hs, 1) |
           bitrotate(hs, -1) |
           bitrotate(hs, ROW_SIZE) |
           bitrotate(hs, -ROW_SIZE) |
           bitrotate(hs, ROW_SIZE + 1) |
           bitrotate(hs, -ROW_SIZE - 1)
end

function get_adjacent_hs(hs::HexSet, new_hs::HexSet)
    for i in 1:HEXSET_NUM_WORDS
        left = (hs.table[i] << 1) | (hs.table[i] >> (sizeof(HEXSET_TYPE) * 8 - 1))
        right = (hs.table[i] >> 1) | (hs.table[i] << (sizeof(HEXSET_TYPE) * 8 - 1))
        new_hs.table[i] = left | right
    end
    # Handle wrap-around between words
    for i in 1:(HEXSET_NUM_WORDS - 1)
        if (hs.table[i] & (1 << (sizeof(HEXSET_TYPE) * 8 - 1))) != 0
            new_hs.table[i + 1] |= 1
        end
        if (hs.table[i + 1] & 1) != 0
            new_hs.table[i] |= (1 << (sizeof(HEXSET_TYPE) * 8 - 1))
        end
    end
    return new_hs
end

function bench_all(; toggle_iters=BOARD_BITS)
    # Warmup to exclude compilation time from the measurements
    bb0 = rand_bitboard()
    _ = get_adjacent_bb(bb0)
    _ = drain(bb0)
    _ = Base.count_ones(bb0)
    _ = Intsect.toggle(bb0, 0)
    println("4 x 64 bit board")

    println("get_adjacent_bb")
    adj = @benchmark get_adjacent_bb(bb) setup = (bb = rand_bitboard())
    display(adj)
    println("get_adjacent_hs")
    adj = @benchmark get_adjacent_hs(hs, new_hs) setup = (hs = rand_hexset(); new_hs = HexSet())
    display(adj)

    println("\nget_and_remove_first_loc repeatedly until empty")
    drn = @benchmark drain(bb) setup = (bb = rand_bitboard())
    display(drn)
    println("\nget_and_remove_first_loc repeatedly until empty (HexSet)")
    drn = @benchmark drain(hs) setup = (hs = rand_hexset())
    display(drn)

    println("\ncount_ones")
    pop = @benchmark Base.count_ones(bb) setup = (bb = rand_bitboard())
    display(pop)
    println("count_ones (HexSet)")
    pop = @benchmark count_ones(hs) setup = (hs = rand_hexset())
    display(pop)

    println("\ntoggle over random locations")
    tog = @benchmark Intsect.toggle(bb, l) setup = (
        bb = rand_bitboard(); l = rand(0:(BOARD_BITS - 1))
    )
    display(tog)
    println("\ntoggle over random locations (HexSet)")
    tog = @benchmark toggle(hs, l) setup = (hs = rand_hexset(); l = rand(0:(BOARD_BITS - 1)))
    display(tog)

    # return (; drn, pop, tog)
end

bench_all()
