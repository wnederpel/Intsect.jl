function f(a::AbstractArray; first=a[begin])
    println("a = $a")
    println("first = $first")
end

f([1, 2]; first=1)

f([1, 2])