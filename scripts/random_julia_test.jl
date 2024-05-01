using Bumper

abstract type MyType end

struct MyStruct <: MyType
    x::Int
end

Base.sizeof(::Type{MyType}) = sizeof(Int)

@no_escape begin
    foo_arr = @alloc(MyType, 10)
    println(foo_arr)
end
