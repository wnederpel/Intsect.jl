using BenchmarkTools
using PProf
using Profile

function f(n::Integer)
    res = 0
    for i in 1:n
        res += i * i * i * i * i * i
    end
    return res
end

n = 1_000_000
@benchmark f($n)
