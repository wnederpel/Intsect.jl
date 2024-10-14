using BenchmarkTools
using PProf
using Profile

@noinline pos(x) = x < 0 ? 0 : x;

function f(x)
    y = pos.(x)
    return @. sin(y * x + 1)
end;

x = rand(100) .- 0.5
(@benchmark f(x)) |> display

Profile.clear()
Profile.@profile for _ in 1:1000
    f(x)
end

PProf.pprof()
