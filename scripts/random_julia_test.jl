using BenchmarkTools

size = 1_000_000

myarr = Vector{Tuple{Integer,Integer}}(undef, size)
(@benchmark foreach(i -> myarr[i] = (i, i), 1:size)) |> display

simple_myarr = Vector{Integer}(undef, size)
(@benchmark foreach(i -> simple_myarr[i] = i, 1:size)) |> display

# Simple integer array with for loop wrapped in a function
function fill_array!(arr::Vector{Int})
    for i in eachindex(arr)
        arr[i] = i
    end
end

simple_myarr2 = Vector{Int}(undef, size)
(@benchmark fill_array!(simple_myarr2)) |> display

# Simple integer array with parallel for loop wrapped in a function
function fill_array_parallel!(arr::Vector{Int})
    Threads.@threads for i in eachindex(arr)
        arr[i] = i
    end
end

simple_myarr3 = Vector{Int}(undef, size)
(@benchmark fill_array_parallel!(simple_myarr3)) |> display

function fill_array_tuple!(arr::Vector{Tuple{Int,Int}})
    for i in eachindex(arr)
        arr[i] = (i, i)
    end
end

simple_myarr4 = Vector{Tuple{Int,Int}}(undef, size)
(@benchmark fill_array_tuple!(simple_myarr4)) |> display

# Repeat this test in C or Rust to see how much faster it is.

println()
