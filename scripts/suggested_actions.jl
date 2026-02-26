using BenchmarkTools
using Intsect

function build_suggested_actions(indices::Vector{Int32})
    actions = Vector{Int32}(undef, length(indices))
    sa = SuggestedActions(0, actions, HexSet(), HexSet())
    for idx in indices
        add!(sa, idx)
    end
    return sa
end

function suggested_contains(sa::SuggestedActions, indices::Vector{Int32})
    hit = 0
    for idx in indices
        if contains(idx, sa)
            hit += 1
        end
    end
    return hit
end

function vector_contains(indices_vec::Vector{Int32}, indices::Vector{Int32})
    hit = 0
    for idx in indices
        if idx in indices_vec
            hit += 1
        end
    end
    return hit
end

random_indices_1 =
    Int32.(
        rand(
            (Intsect.MAX_PLACEMENT_INDEX):(Intsect.MAX_PLACEMENT_INDEX + Intsect.MAX_MOVEMENT_INDEX),
            10,
        )
    )
random_indices_2 =
    Int32.(
        rand(
            (Intsect.MAX_PLACEMENT_INDEX):(Intsect.MAX_PLACEMENT_INDEX + Intsect.MAX_MOVEMENT_INDEX),
            150,
        )
    )
random_indices_1 = vcat(Int32.(rand(random_indices_2, 10)), random_indices_1)

sa = build_suggested_actions(random_indices_1)
show(sa.moving_loc_hs)
show(sa.goal_loc_hs)
indices_vec = random_indices_1

suggested_hit = suggested_contains(sa, random_indices_2)
vector_hit = vector_contains(indices_vec, random_indices_2)
println(vector_hit)
@assert suggested_hit == vector_hit

println("SuggestedActions contains:")
suggested_bench = @benchmark suggested_contains($sa, $random_indices_2)
show(stdout, "text/plain", suggested_bench)

println("\n\nVector in contains:")
vector_bench = @benchmark vector_contains($indices_vec, $random_indices_2)
show(stdout, "text/plain", vector_bench)

using PProf: PProf
using Profile: Profile

# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 1 suggested_contains(sa, random_indices_2)
# PProf.Allocs.pprof()

Profile.clear()
Profile.@profile for i in 1:100_000
    suggested_contains(sa, random_indices_2)
end
PProf.pprof()

println()
