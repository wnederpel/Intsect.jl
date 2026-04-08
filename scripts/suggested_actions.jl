using BenchmarkTools
using Intsect
using Bumper

function build_suggested_actions(indices::AbstractVector{Int32})
    actions = Vector{Int32}(undef, length(indices))
    sa = SuggestedActions(0, indices, HexSet(), HexSet())
    for idx in indices
        add!(sa, idx)
    end
    return sa
end

function suggested_contains(sa::SuggestedActions, indices::Vector{Int32})
    hit = 0
    for idx in indices
        if Base.contains(idx, sa)
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

# random_indices_1 =
#     Int32.(
#         rand(
#             (Intsect.MAX_PLACEMENT_INDEX):(Intsect.MAX_PLACEMENT_INDEX + Intsect.MAX_MOVEMENT_INDEX),
#             10,
#         )
#     )
# random_indices_2 =
#     Int32.(
#         rand(
#             (Intsect.MAX_PLACEMENT_INDEX):(Intsect.MAX_PLACEMENT_INDEX + Intsect.MAX_MOVEMENT_INDEX),
#             150,
#         )
#     )
# random_indices_1 = vcat(Int32.(rand(random_indices_2, 10)), random_indices_1)

@no_escape begin
    buff = @alloc(eltype(Int32), 5)
    for i in 1:5
        buff[i] = Int32(-1)
    end
    sa = build_suggested_actions(buff)
    for i in 1:5
        add!(sa, Int32(i))
    end
    println(Base.contains(Int32(1), sa))
    add!(sa, Int32(6))
    println(Base.contains(Int32(1), sa))
    println(Base.contains(Int32(6), sa))

    # random_indices_1 = vcat(Int32.(rand(random_indices_2, 10)), random_indices_1)
    # buff = @alloc(eltype(Int32), length(random_indices_1))
    # for i in eachindex(random_indices_1)
    #     buff[i] = random_indices_1[i]
    # end

    # sa = build_suggested_actions(buff)
    # show(sa.moving_loc_hs)
    # show(sa.goal_loc_hs)
    # indices_vec = random_indices_1

    # suggested_hit = suggested_contains(sa, random_indices_2)
    # vector_hit = vector_contains(indices_vec, random_indices_2)
    # println(vector_hit)
    # @assert suggested_hit == vector_hit

    # println("SuggestedActions contains:")
    # suggested_bench = @benchmark suggested_contains($sa, $random_indices_2)
    # show(stdout, "text/plain", suggested_bench)

    # println("\n\nVector in contains:")
    # vector_bench = @benchmark vector_contains($indices_vec, $random_indices_2)
    # show(stdout, "text/plain", vector_bench)
end
