using BenchmarkTools
# TODO: test MVectors vs SizedVectors of static arrays
n = 100_000_000

x = rand(n)

y = rand(n)

a = exp(1)

function axpy_multi(x, y, a)
    Threads.@threads for i in eachindex(x)
        y[i] += a * x[i]
    end
    return y
end

function axpy_other(x, y, a)
    return @. a * x + y
end

function axpy_inplace!(x, y, a)
    @. y += a * x
end

@btime axpy_multi(x, y, a) setup = (y = rand(n))
@btime axpy_other(x, y, a) setup = (y = rand(n))
@btime axpy_inplace!(x, y, a) setup = (y = rand(n))

println()
