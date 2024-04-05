using Test, TestItems, TestItemRunner
using Intsect

include("move_generation_test_basic.jl")
include("move_generation_test_special.jl")
include("placement_generation_test.jl")
include("valid_actions_test.jl")
# TODO test: add 'game' tests
# doing move increases ply, current color, and turn
# doing move updates queen state
# doing move updates underworld

@run_package_tests verbose = true