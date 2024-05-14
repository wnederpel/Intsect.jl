module Intsect

using Revise
using StaticArrays
using EnumX
using DataStructures
using Memoize
using Base.Threads
using Bumper

# structs
export Board
export Move
export Placement
export Climb
export Pass
export GameString
export Action
export End

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
export MAX_NUMS
# Constants for move generation, constructed in game
export ALL_PLACMENETS
export ALL_MOVEMENTS
export ALL_CLIMBS

# enums
export Bug
export Gametype
export Direction

# methods
export example
export start
export perft
export direction_from_string
export show
export handle_newgame_command
export get_tile_from_string
export get_tile_info
export get_tile_name
export get_tile_height
export get_tile_bug
export get_tile_bug_num
export get_tile_color
export get_pinned_tiles
export allneighs
export apply_direction
export action_from_move_string
export do_action
export validactions
export isvalid_shifted_tile
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
export move_string_from_action
export gamestring
export undo
export get_pinned_tiles
export format_with_dots
export extract_valid_actions
export get_all_placements

# Files
include("enums.jl")
include("constants.jl")
include("structs.jl")
include("game.jl")
include("main.jl")
include("show_methods.jl")
include("move_generation.jl")
include("perft.jl")

end # module Intsect
