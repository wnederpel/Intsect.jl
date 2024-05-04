using Bumper
using BenchmarkTools

abstract type MyType end

struct MyStruct <: MyType
    x::Int
end

mutable struct MyBoard
    arr::Vector{MyStruct}
end

Base.sizeof(::Type{MyStruct}) = sizeof(Int)

@benchmark begin
    @no_escape begin
        arr = @alloc(MyStruct, 10)
        board = MyBoard(arr)
        fill!(board.arr, MyStruct(1))

        sum(x -> x.x, board.arr)
    end
end
