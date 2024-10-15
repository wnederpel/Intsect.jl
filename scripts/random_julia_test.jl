using Bumper
using BenchmarkTools

function add_one(x::Ptr)
    unsafe_store!(x, unsafe_load(x) + 1)
    return nothing
end

function min_one(x::Ref)
    x[] -= 1
    return nothing
end

function test_func()
    test = Ptr{Int}()
    unsafe_store!(test, 10)
    val = unsafe_load(test)
    return val
end

@noinline function validactions!(move_buffer, ref)
    move_buffer[ref[1]] = 1
    ref[1] += 1
    move_buffer[ref[1]] = 2
    ref[1] += 1
    move_buffer[ref[1]] = 5
    return nothing
end

function g(d)
    if d == 1
        @no_escape begin
            move_buffer = @alloc(Int, 50)
            ref_buffer = @alloc(Int, 1)
            ref_buffer[1] = 1
            validactions!(move_buffer, ref_buffer)
        end
        return ref_buffer[1] + 1
    end
    @no_escape begin
        ref = Ref{Int}(d)
        val = 0
        for _ in 1:(ref[] - 1)
            val += g(d - 1)
        end
    end

    return val
end

function f(depth; output=true)
    for depth in 1:depth
        nodes, time_taken, memory_allocated, gc_time, _ = @timed g(depth)
        if output
            println("Perft($depth) \t = $(format_with_dots(nodes))")
            kilo_nodes = nodes / 1000
            println("KN/S \t\t = $(format_with_dots(Int.(round(kilo_nodes / time_taken))))")
            println("memory per node  = $(round(memory_allocated / nodes, digits=2)) bytes")
            println("gc time \t = $(round(gc_time*100))%")
            println("total time \t = $(round(time_taken, digits=2)) seconds")
            println()
        end
    end
end

@btime f(1; output=false)