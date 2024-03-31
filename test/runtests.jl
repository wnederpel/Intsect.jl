using Test, TestItems, TestItemRunner
using Intsect

include("move_generation_test_basic.jl")
include("move_generation_test_special.jl")

@run_package_tests verbose = true