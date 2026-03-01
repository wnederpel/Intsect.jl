using Test, TestItems, TestItemRunner
using Intsect

Intsect.SUPPRESS_ACTION_ERROR_OUTPUT[] = true

include("move_generation_test_basic.jl")
include("move_generation_test_special.jl")
include("placement_generation_test.jl")
include("valid_actions_test.jl")
include("game_tests.jl")
include("bb_tests.jl")
include("perft_diff_test.jl")
include("ladybug_tests.jl")
include("pillbug_tests.jl")

@run_package_tests verbose = true