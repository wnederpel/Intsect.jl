using EnumX

# Define an EnumX type

abstract type MyVals end

struct val_a <: MyVals end
struct val_b <: MyVals end
struct val_c <: MyVals end

# Generated function returning a filtered list (fully pure)
@generated function filter_by_enum(::Type{T}, lst) where {T<:MyVals}
    if T === val_a
        return :(filter(x -> x in (1, 2, 3), lst))
    elseif T === val_b
        return :(filter(x -> x in (4, 5, 6), lst))
    elseif T === val_c
        return :(filter(x -> x in (7, 8, 9), lst))
    else
        throw(ArgumentError("Unsupported type"))
    end
end

my_filter(x, lst) = filter(val -> val == x, lst)

@generated function foo(x, lst)
    Core.println(x)
    return :(my_filter(x, lst))
end

foo(2, [1, 2]) |> println
foo(2, [1, 2]) |> println

# Example Usage
data = [1, 2, 3, 4, 5, 6, 7, 8, 9]

# Example Usage
data = [1, 2, 3, 4, 5, 6, 7, 8, 9]

# Iterate lazily over the generator (no allocations)
result = filter_by_enum(val_a, data)
for x in result
    println(x)  # Output: 1, 2, 3
end
