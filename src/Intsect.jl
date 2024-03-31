module Intsect

using Revise
using StaticArrays
using EnumX
using DataStructures

# constants
export GRID_SIZE
export ROW_SIZE
export GAMETYPE
export BOARD
export EMPTY_TILE
export NOT_PLACED
export INVALID_LOC
export MID

# enums
export Bug
export Gametype
export Direction

# methods
export direction_from_string
export main
export show
export handle_newgame_command
export get_tile_from_string
export get_tile_info
export get_tile_name
export allneighs
export apply_direction
export action_from_move_string
export do_action
export validmoves
export isvalid_shifted_tile
export get_tile_on_board
export generate_placement_locs
export push_slidelocs!
export antmoves
export grasshoppermoves
export spidermoves
export beetlemoves
export ladybugmoves
export queenmoves
export pillbugmoves
export mosquitomoves
export handle_newgame_command
export set_tile_on_board

# structs
export Board
export Move
export Placement
export Pass
export Climb

# Files
include("game.jl")
include("main.jl")
include("show_methods.jl")
include("move_generation.jl")

end # module Intsect
