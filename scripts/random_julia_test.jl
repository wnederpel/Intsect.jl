using PProf
using Profile

function f(a, b)
    for _ in 1:1_000_000
        a[b[1] += 1] = 5.0
    end
    b[1] = 0
    return a[end]
end

a = rand(1_000_000)
b = [0]

f(a, b)
@btime f($a, $b)
