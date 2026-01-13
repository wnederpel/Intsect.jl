using Printf
using BenchmarkTools
using Intsect
using PProf
using Profile

function main()
    game_strings = [
        raw"Base+MLP;InProgress;white[5];wL;bL wL\;wM \wL;bM bL\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-;wA2 wQ\;bA2 bA1\;wA2 /bA2;bA1 /wA1;wB1 wQ\;bP bA2-;wM wB1\;bB1 \bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1",
    ]

    # b = @benchmarkable begin
    #     run_benchmark($game_strings, $depth)
    # end
    # t = run(b; seconds=30)
    # display(t)
    Profile.clear()
    Profile.@profile run_benchmark(game_strings)
    PProf.pprof()
    open("tmp/prof.txt", "w") do s
        Profile.print(IOContext(s, :displaysize => (24, 500)))
    end
    return nothing
end

function run_benchmark(game_strings::Vector{String})
    for game_string in game_strings
        perft(5; game_string=game_string, output=false)
    end

    return nothing
end

main()
