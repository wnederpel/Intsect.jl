using EnumX

# Define an EnumX type

abstract type MyVals end

struct val_a <: MyVals end
struct val_b <: MyVals end
struct val_c <: MyVals end

my_filter(lst, filters) = filter(val -> val ∉ filters, lst)

# Generated function returning a filtered list (fully pure)
@generated function filter_by_enum(::Type{T}, lst) where {T<:MyVals}
    if T === val_a
        return :(my_filter(lst, (1, 2, 3)))
    elseif T === val_b
        return :(my_filter(lst, (4, 5, 6)))
    elseif T === val_c
        return :(my_filter(lst, (7, 8, 9)))
    else
        throw(ArgumentError("Unsupported type"))
    end
end

# Example Usage
data = [1, 2, 3, 4, 5, 6, 7, 8, 9]

function f(val::Type{T}) where {T<:MyVals}
    println(val)
end

f(val_b)

# Iterate lazily over the generator (no allocations)
result = filter_by_enum(val_b, data)
for x in result
    println(x)  # Output: 1, 2, 3
end
