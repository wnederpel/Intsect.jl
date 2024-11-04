using BenchmarkTools

b = UInt128(2)^UInt128(65)
c = UInt128(2)^UInt128(124)
d = 2^30

const VAL1::UInt128 = UInt128(2)^UInt128(64) - 1
const VAL2::UInt128 = 2^32 - 1
const VAL3::UInt128 = 2^16 - 1
const VAL4::UInt128 = 2^8 - 1
const VAL5::UInt128 = 2^4 - 1
const VAL6::UInt128 = 2^2 - 1
const VAL7::UInt128 = 2^1 - 1
function custom_log(num::Number)
    val = 0

    if num & VAL1 == 0
        val += 64
        num = num >> 64
    end
    if num & VAL2 == 0
        val += 32
        num = num >> 32
    end
    if num & VAL3 == 0
        val += 16
        num = num >> 16
    end
    if num & VAL4 == 0
        val += 8
        num = num >>> 8
    end
    if num & VAL5 == 0
        val += 4
        num = num >>> 4
    end
    if num & VAL6 == 0
        val += 2
        num = num >>> 2
    end
    if num & VAL7 == 0
        val += 1
        num = num >>> 1
    end
    return val
end

println(log2(b))
println(log2(c))
println(log2(d))
println(custom_log(b))
println(custom_log(c))
println(custom_log(d))

@btime log2($b)
@btime log2($c)
@btime log2($d)
@btime custom_log($b)
@btime custom_log($c)
@btime custom_log($d)

println()