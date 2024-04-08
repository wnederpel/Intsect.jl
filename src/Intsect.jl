module Intsect

using Revise
using StaticArrays
using EnumX
using DataStructures

# structs
export Board
export Move
export Placement
export Climb
export Pass

# constants
export GRID_SIZE
export ROW_SIZE
export GAMETYPE
export BOARD
export EMPTY_TILE
export NOT_PLACED
export INVALID_LOC
export MID
export WHITE
export BLACK

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
export get_tile_height
export get_tile_color
export allneighs
export apply_direction
export action_from_move_string
export do_action
export validactions
export isvalid_shifted_tile
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
export get_tile_on_board
export set_tile_on_board
export set_loc
export get_loc

# Files
include("enums.jl")
include("constants.jl")
include("structs.jl")
include("game.jl")
include("main.jl")
include("show_methods.jl")
include("move_generation.jl")

end # module Intsect
