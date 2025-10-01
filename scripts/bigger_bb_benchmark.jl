using BenchmarkTools, Random, Intsect

# Assume BitBoard and the functions from your module are loaded.
const BOARD_BITS = 64 * fieldcount(BitBoard)

function rand_bitboard()
    BitBoard(rand(UInt64), rand(UInt64), rand(UInt64), rand(UInt64))
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

function bench_all(; toggle_iters=BOARD_BITS)
    # Warmup to exclude compilation time from the measurements
    bb0 = rand_bitboard()
    _ = get_adjacent_bb(bb0)
    _ = drain(bb0)
    _ = Base.count_ones(bb0)
    _ = toggle(bb0, 0)
    println("9 x 64")

    println("get_adjacent_bb")
    adj = @benchmark get_adjacent_bb(bb) setup = (bb = rand_bitboard())
    display(adj)

    println("\nget_and_remove_first_loc repeatedly until empty")
    drn = @benchmark drain(bb) setup = (bb = rand_bitboard())
    display(drn)

    println("\ncount_ones")
    pop = @benchmark Base.count_ones(bb) setup = (bb = rand_bitboard())
    display(pop)

    println("\ntoggle over random locations")
    tog = @benchmark begin
        bb2 = bb
        @inbounds for l in locs
            bb2 = toggle(bb2, l)
        end
        bb2
    end setup = (bb = rand_bitboard(); locs = rand(0:(BOARD_BITS - 1), $toggle_iters))
    display(tog)

    return (; adj, drn, pop, tog)
end

bench_all()
