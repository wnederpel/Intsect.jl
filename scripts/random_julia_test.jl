function fib(n::Int64)::Int64
    n <= 2 && return 1
    n == 3 && return 2
    fib(n - 1) + fib(n - 2)
end

@time fib(10);
@time fib(50);
