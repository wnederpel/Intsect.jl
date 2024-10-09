using BenchmarkTools
using Bumper

moves = rand(1000)

struct Test
    x::Vector
end

test = Test(ones(1000))

function get_moves(depth)
    val = 0
    @no_escape begin
        x = @alloc(Int64, 1000)

        for i in Int64(1):Int64(1000)
            if depth == 1
                x[i] = i::Int64
            else
                x[i] = get_moves(depth - 1)
            end
        end

        val = sum(x)
    end

    return val
end

@btime get_moves($2)