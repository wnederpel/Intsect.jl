using BitIntegers, BenchmarkTools, Random

const U256 = UInt256
const U1024 = UInt1024
const U128 = UInt128

"4 × 256-bit limbs"
struct BB4x256
    x::NTuple{4,U256}
end

"16 × 64-bit limbs"
struct BB16x64
    x1::UInt64
    x2::UInt64
    x3::UInt64
    x4::UInt64
    x5::UInt64
    x6::UInt64
    x7::UInt64
    x8::UInt64
    x9::UInt64
    x10::UInt64
    x11::UInt64
    x12::UInt64
    x13::UInt64
    x14::UInt64
    x15::UInt64
    x16::UInt64
end

# ---------- Bitwise ----------
@inline Base.:|(a::BB16x64, b::BB16x64) = BB16x64(
    a.x1 | b.x1,
    a.x2 | b.x2,
    a.x3 | b.x3,
    a.x4 | b.x4,
    a.x5 | b.x5,
    a.x6 | b.x6,
    a.x7 | b.x7,
    a.x8 | b.x8,
    a.x9 | b.x9,
    a.x10 | b.x10,
    a.x11 | b.x11,
    a.x12 | b.x12,
    a.x13 | b.x13,
    a.x14 | b.x14,
    a.x15 | b.x15,
    a.x16 | b.x16,
)

@inline Base.:&(a::BB16x64, b::BB16x64) = BB16x64(
    a.x1 & b.x1,
    a.x2 & b.x2,
    a.x3 & b.x3,
    a.x4 & b.x4,
    a.x5 & b.x5,
    a.x6 & b.x6,
    a.x7 & b.x7,
    a.x8 & b.x8,
    a.x9 & b.x9,
    a.x10 & b.x10,
    a.x11 & b.x11,
    a.x12 & b.x12,
    a.x13 & b.x13,
    a.x14 & b.x14,
    a.x15 & b.x15,
    a.x16 & b.x16,
)

@inline Base.:⊻(a::BB16x64, b::BB16x64) = BB16x64(
    a.x1 ⊻ b.x1,
    a.x2 ⊻ b.x2,
    a.x3 ⊻ b.x3,
    a.x4 ⊻ b.x4,
    a.x5 ⊻ b.x5,
    a.x6 ⊻ b.x6,
    a.x7 ⊻ b.x7,
    a.x8 ⊻ b.x8,
    a.x9 ⊻ b.x9,
    a.x10 ⊻ b.x10,
    a.x11 ⊻ b.x11,
    a.x12 ⊻ b.x12,
    a.x13 ⊻ b.x13,
    a.x14 ⊻ b.x14,
    a.x15 ⊻ b.x15,
    a.x16 ⊻ b.x16,
)

@inline Base.:~(a::BB16x64) = BB16x64(
    ~a.x1,
    ~a.x2,
    ~a.x3,
    ~a.x4,
    ~a.x5,
    ~a.x6,
    ~a.x7,
    ~a.x8,
    ~a.x9,
    ~a.x10,
    ~a.x11,
    ~a.x12,
    ~a.x13,
    ~a.x14,
    ~a.x15,
    ~a.x16,
)

# ---------- Toggle one bit ----------
@inline function toggle(a::BB16x64, k::Int)
    k &= 1023
    q = k >>> 6
    r = k & 63
    m = UInt64(1) << r
    q == 0 && return BB16x64(
        a.x1 ⊻ m,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 1 && return BB16x64(
        a.x1,
        a.x2 ⊻ m,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 2 && return BB16x64(
        a.x1,
        a.x2,
        a.x3 ⊻ m,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 3 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4 ⊻ m,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 4 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5 ⊻ m,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 5 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6 ⊻ m,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 6 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7 ⊻ m,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 7 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8 ⊻ m,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 8 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9 ⊻ m,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 9 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10 ⊻ m,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 10 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11 ⊻ m,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 11 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12 ⊻ m,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 12 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13 ⊻ m,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 13 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14 ⊻ m,
        a.x15,
        a.x16,
    )
    q == 14 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15 ⊻ m,
        a.x16,
    )
    # q==15
    return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16 ⊻ m,
    )
end

# ---------- Rotate left by k (0..1023) ----------
@inline function rotl(a::BB16x64, k::Integer)
    s = k & 1023
    s == 0 && return a
    q = (s >>> 6) & 15
    r = s & 63
    r == 0 && return _rotl_limb(a, q)
    return _rotl_limb_intra(a, q, r)
end

# limb-only rotate (r==0)
@inline function _rotl_limb(a::BB16x64, q::Int)
    q == 0 && return BB16x64(
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
    )
    q == 1 && return BB16x64(
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
    )
    q == 2 && return BB16x64(
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
    )
    q == 3 && return BB16x64(
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
    )
    q == 4 && return BB16x64(
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
    )
    q == 5 && return BB16x64(
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
    )
    q == 6 && return BB16x64(
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
    )
    q == 7 && return BB16x64(
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
    )
    q == 8 && return BB16x64(
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
    )
    q == 9 && return BB16x64(
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
    )
    q == 10 && return BB16x64(
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
    )
    q == 11 && return BB16x64(
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
        a.x5,
    )
    q == 12 && return BB16x64(
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
        a.x4,
    )
    q == 13 && return BB16x64(
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
        a.x3,
    )
    q == 14 && return BB16x64(
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
        a.x2,
    )
    # q==15
    return BB16x64(
        a.x2,
        a.x3,
        a.x4,
        a.x5,
        a.x6,
        a.x7,
        a.x8,
        a.x9,
        a.x10,
        a.x11,
        a.x12,
        a.x13,
        a.x14,
        a.x15,
        a.x16,
        a.x1,
    )
end

# limb rotate + intra-limb carry (r!=0)
@inline function _rotl_limb_intra(a::BB16x64, q::Int, r::Int)
    shl = r
    shr = 64 - r
    if q == 0
        return BB16x64(
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
        )
    elseif q == 1
        return BB16x64(
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
        )
    elseif q == 2
        return BB16x64(
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
        )
    elseif q == 3
        return BB16x64(
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
        )
    elseif q == 4
        return BB16x64(
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
        )
    elseif q == 5
        return BB16x64(
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
        )
    elseif q == 6
        return BB16x64(
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
        )
    elseif q == 7
        return BB16x64(
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
        )
    elseif q == 8
        return BB16x64(
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
        )
    elseif q == 9
        return BB16x64(
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
        )
    elseif q == 10
        return BB16x64(
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
        )
    elseif q == 11
        return BB16x64(
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
        )
    elseif q == 12
        return BB16x64(
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
        )
    elseif q == 13
        return BB16x64(
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
        )
    elseif q == 14
        return BB16x64(
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
            (a.x2 << shl) | (a.x3 >>> shr),
        )
    else # q==15
        return BB16x64(
            (a.x2 << shl) | (a.x3 >>> shr),
            (a.x3 << shl) | (a.x4 >>> shr),
            (a.x4 << shl) | (a.x5 >>> shr),
            (a.x5 << shl) | (a.x6 >>> shr),
            (a.x6 << shl) | (a.x7 >>> shr),
            (a.x7 << shl) | (a.x8 >>> shr),
            (a.x8 << shl) | (a.x9 >>> shr),
            (a.x9 << shl) | (a.x10 >>> shr),
            (a.x10 << shl) | (a.x11 >>> shr),
            (a.x11 << shl) | (a.x12 >>> shr),
            (a.x12 << shl) | (a.x13 >>> shr),
            (a.x13 << shl) | (a.x14 >>> shr),
            (a.x14 << shl) | (a.x15 >>> shr),
            (a.x15 << shl) | (a.x16 >>> shr),
            (a.x16 << shl) | (a.x1 >>> shr),
            (a.x1 << shl) | (a.x2 >>> shr),
        )
    end
end

# ---------- Adjacency / Placement ----------
@inline adj(x::BB16x64, ROW) =
    x |
    rotl(x, 1) |
    rotl(x, -1) |
    rotl(x, ROW) |
    rotl(x, -ROW) |
    rotl(x, ROW + 1) |
    rotl(x, -ROW - 1)

@inline place(p::BB16x64, w::BB16x64, b::BB16x64, wtm::Bool, ROW) =
    wtm ? ((p | adj(w, ROW)) & ~(adj(b, ROW) | w | b)) :
    ((p | adj(b, ROW)) & ~(adj(w, ROW) | w | b))

# ---------- Pop least-significant 1 ----------
@inline function poplsb(a::BB16x64)
    a.x1 != 0 && return (
        trailing_zeros(a.x1),
        BB16x64(
            a.x1 & (a.x1 - 1),
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x2 != 0 && return (
        trailing_zeros(a.x2) + 64,
        BB16x64(
            a.x1,
            a.x2 & (a.x2 - 1),
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x3 != 0 && return (
        trailing_zeros(a.x3) + 128,
        BB16x64(
            a.x1,
            a.x2,
            a.x3 & (a.x3 - 1),
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x4 != 0 && return (
        trailing_zeros(a.x4) + 192,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4 & (a.x4 - 1),
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x5 != 0 && return (
        trailing_zeros(a.x5) + 256,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5 & (a.x5 - 1),
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x6 != 0 && return (
        trailing_zeros(a.x6) + 320,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6 & (a.x6 - 1),
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x7 != 0 && return (
        trailing_zeros(a.x7) + 384,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7 & (a.x7 - 1),
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x8 != 0 && return (
        trailing_zeros(a.x8) + 448,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8 & (a.x8 - 1),
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x9 != 0 && return (
        trailing_zeros(a.x9) + 512,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9 & (a.x9 - 1),
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x10 != 0 && return (
        trailing_zeros(a.x10) + 576,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10 & (a.x10 - 1),
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x11 != 0 && return (
        trailing_zeros(a.x11) + 640,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11 & (a.x11 - 1),
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x12 != 0 && return (
        trailing_zeros(a.x12) + 704,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12 & (a.x12 - 1),
            a.x13,
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x13 != 0 && return (
        trailing_zeros(a.x13) + 768,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13 & (a.x13 - 1),
            a.x14,
            a.x15,
            a.x16,
        ),
    )
    a.x14 != 0 && return (
        trailing_zeros(a.x14) + 832,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14 & (a.x14 - 1),
            a.x15,
            a.x16,
        ),
    )
    a.x15 != 0 && return (
        trailing_zeros(a.x15) + 896,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15 & (a.x15 - 1),
            a.x16,
        ),
    )
    a.x16 != 0 && return (
        trailing_zeros(a.x16) + 960,
        BB16x64(
            a.x1,
            a.x2,
            a.x3,
            a.x4,
            a.x5,
            a.x6,
            a.x7,
            a.x8,
            a.x9,
            a.x10,
            a.x11,
            a.x12,
            a.x13,
            a.x14,
            a.x15,
            a.x16 & (a.x16 - 1),
        ),
    )
    return (-1, a)
end

# ---------- Zero constants ----------
const Z16x64 = BB16x64(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

# ---------- Adj/Place helpers for benches ----------
@inline adj(x::BB16x64) =
    x | rotl(x, 1) | rotl(x, -1) | rotl(x, 16) | rotl(x, -16) | rotl(x, 17) | rotl(x, -17)

@inline place_white_turn(p::BB16x64, w::BB16x64, b::BB16x64) = (p | adj(w)) & ~(adj(b) | w | b)

@inline place_black_turn(p::BB16x64, w::BB16x64, b::BB16x64) = (p | adj(b)) & ~(adj(w) | w | b)

# adjacency / placement (same API as before)
@inline adj(x, ROW) =
    x |
    rotl(x, 1) |
    rotl(x, -1) |
    rotl(x, ROW) |
    rotl(x, -ROW) |
    rotl(x, ROW + 1) |
    rotl(x, -ROW - 1)
@inline place(p, w, b, wtm::Bool, ROW) =
    wtm ? ((p | adj(w, ROW)) & ~(adj(b, ROW) | w | b)) :
    ((p | adj(b, ROW)) & ~(adj(w, ROW) | w | b))

# ---------------- Bitwise ops ----------------
@inline Base.:|(a::BB4x256, b::BB4x256) = (
    ax = a.x; bx = b.x; BB4x256((ax[1] | bx[1], ax[2] | bx[2], ax[3] | bx[3], ax[4] | bx[4]))
)
@inline Base.:&(a::BB4x256, b::BB4x256) = (
    ax = a.x; bx = b.x; BB4x256((ax[1] & bx[1], ax[2] & bx[2], ax[3] & bx[3], ax[4] & bx[4]))
)
@inline Base.:⊻(a::BB4x256, b::BB4x256) = (
    ax = a.x;
    bx = b.x;
    BB4x256((ax[1] ⊻ bx[1], ax[2] ⊻ bx[2], ax[3] ⊻ bx[3], ax[4] ⊻ bx[4]))
)
@inline Base.:~(a::BB4x256) = (ax = a.x; BB4x256((~ax[1], ~ax[2], ~ax[3], ~ax[4])))

# ---------------- Toggle one bit ----------------
@inline toggle(x::U1024, k::Int) = x ⊻ (U1024(1) << (k & 1023))

@inline function toggle(bb::BB4x256, k::Int)
    q = (k & 1023) >>> 8               # 0..3
    r = k & 255
    a0, a1, a2, a3 = bb.x
    if q == 0
        a0 ⊻= (U256(1) << r)
    elseif q == 1
        a1 ⊻= (U256(1) << r)
    elseif q == 2
        a2 ⊻= (U256(1) << r)
    else
        a3 ⊻= (U256(1) << r)
    end
    BB4x256((a0, a1, a2, a3))
end

# ---------------- Rotates ----------------
@inline rotl(x::U1024, k::Integer) = (x << (k & 1023)) | (x >>> ((-k) & 1023))

@inline function rotl(bb::BB4x256, k::Integer)
    s = k & 1023
    s == 0 && return bb
    q = (s >>> 8) & 3                  # limb rotate
    r = s & 255
    a = ntuple(i -> bb.x[((i - q - 1) & 3) + 1], 4)
    r == 0 && return BB4x256(a)
    a0, a1, a2, a3 = a
    b0 = (a0 << r) | (a1 >>> (256 - r))
    b1 = (a1 << r) | (a2 >>> (256 - r))
    b2 = (a2 << r) | (a3 >>> (256 - r))
    b3 = (a3 << r) | (a0 >>> (256 - r))
    BB4x256((b0, b1, b2, b3))
end

# ---------------- Adjacency / Placement ----------------
@inline adj(x, ROW) =
    x |
    rotl(x, 1) |
    rotl(x, -1) |
    rotl(x, ROW) |
    rotl(x, -ROW) |
    rotl(x, ROW + 1) |
    rotl(x, -ROW - 1)
@inline place(p, w, b, wtm::Bool, ROW) =
    wtm ? ((p | adj(w, ROW)) & ~(adj(b, ROW) | w | b)) :
    ((p | adj(b, ROW)) & ~(adj(w, ROW) | w | b))

# ---------------- Pop LSB ----------------
@inline poplsb(x::U1024) = x == 0 ? (-1, x) : (trailing_zeros(x), x & (x - U1024(1)))

@inline function poplsb(bb::BB4x256)
    a0, a1, a2, a3 = bb.x
    if a0 != 0
        (trailing_zeros(a0), BB4x256((a0 & (a0 - U256(1)), a1, a2, a3)))
    elseif a1 != 0
        (trailing_zeros(a1) + 256, BB4x256((a0, a1 & (a1 - U256(1)), a2, a3)))
    elseif a2 != 0
        (trailing_zeros(a2) + 512, BB4x256((a0, a1, a2 & (a2 - U256(1)), a3)))
    elseif a3 != 0
        (trailing_zeros(a3) + 768, BB4x256((a0, a1, a2, a3 & (a3 - U256(1)))))
    else
        (-1, bb)
    end
end

# ---------------- Random sparse gens ----------------
function rand_sparse(::Type{U1024}; p=0.02, rng=Random.default_rng())
    # build via limbs to avoid 1024 iterations
    limbs = ntuple(_ -> begin
        x = U256(0)
        @inbounds for i in 0:255
            rand(rng) < p && (x |= (U256(1) << i))
        end
        x
    end, 4)
    # pack limbs: UInt1024 constructor from limbs exists via reinterpret
    reinterpret(U1024, limbs)
end

function rand_sparse(::Type{BB4x256}; p=0.02, rng=Random.default_rng())
    BB4x256(ntuple(_ -> begin
        x = U256(0)
        @inbounds for i in 0:255
            rand(rng) < p && (x |= (U256(1) << i))
        end
        x
    end, 4))
end
# Bernoulli(p) per bit, independent
function rand_sparse(::Type{BB16x64}; p=0.02, rng=Random.default_rng())
    @inline limb(p, rng) = begin
        z = UInt64(0)
        @inbounds for i in 0:63
            rand(rng) < p && (z |= (UInt64(1) << i))
        end
        z
    end
    BB16x64(
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
        limb(p, rng),
    )
end
# ---------------- Bench harness ----------------
function bench_all(; ROW=16, toggles=500_000, drains=10_000)
    rng = MersenneTwister(42)

    x1024 = rand_sparse(U1024; p=0.05, rng)
    ms = rand(rng, 0:1023, toggles)
    w1024 = rand_sparse(U1024; p=0.03, rng)
    b1024 = rand_sparse(U1024; p=0.03, rng)

    x4x256 = rand_sparse(BB4x256; p=0.05, rng)
    w4x256 = rand_sparse(BB4x256; p=0.03, rng)
    b4x256 = rand_sparse(BB4x256; p=0.03, rng)

    x16x64 = rand_sparse(BB16x64; p=0.05, rng)
    w16x64 = rand_sparse(BB16x64; p=0.03, rng)
    b16x64 = rand_sparse(BB16x64; p=0.03, rng)

    println("== 16×UInt64 ==")
    @btime begin
        local x = $x16x64
        @inbounds for k in $ms
            x = toggle(x, k)
        end
        x
    end
    @btime adj($x16x64, $ROW)
    @btime place(Z16x64, $w16x64, $b16x64, true, $ROW)
    @btime place(Z16x64, $w16x64, $b16x64, false, $ROW)
    @btime begin
        local s = 0
        local y = $x16x64
        for _ in 1:($drains)
            i, y = poplsb(y)
            i < 0 && break
            s += i
        end
        s
    end

    println("== 4×UInt256 ==")
    @btime begin
        local x = $x4x256
        @inbounds for k in $ms
            x = toggle(x, k)
        end
        x
    end
    @btime adj($x4x256, $ROW)
    @btime place(BB4x256((U256(0), U256(0), U256(0), U256(0))), $w4x256, $b4x256, true, $ROW)
    @btime place(BB4x256((U256(0), U256(0), U256(0), U256(0))), $w4x256, $b4x256, false, $ROW)
    @btime begin
        local s = 0
        local y = $x4x256
        for _ in 1:($drains)
            i, y = poplsb(y)
            i < 0 && break
            s += i
        end
        s
    end

    println("== UInt1024 ==")
    @btime begin
        local x = $x1024
        @inbounds for k in $ms
            x = toggle(x, k)
        end
        x
    end
    @btime adj($x1024, $ROW)
    @btime place(zero($U1024), $w1024, $b1024, true, $ROW)
    @btime place(zero($U1024), $w1024, $b1024, false, $ROW)
    @btime begin
        local s = 0
        local y = $x1024
        for _ in 1:($drains)
            i, y = poplsb(y)
            i < 0 && break
            s += i
        end
        s
    end
end

bench_all()
