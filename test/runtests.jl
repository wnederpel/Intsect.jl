using Test, TestItems, TestItemRunner
using Intsect

include("move_generation_test_basic.jl")
include("move_generation_test_special.jl")
include("placement_generation_test.jl")
include("valid_actions_test.jl")
include("game_tests.jl")
# TODO test: add tests for move / game string generation
# TODO test: add tests for allowing special pillbug moves when pillbug itself is pinned, also via mosquito 

@run_package_tests verbose = true