module Intsect

using StaticArrays
using EnumX
using DataStructures
using Bumper
using InteractiveUtils
using Printf

# structs
export Board
export Move
export Placement
export Climb
export Pass
export GameString
export Action
export HexSet

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
export PERFT_BUFFER
# Constants for move generation, constructed in game
export ALL_ACTIONS
export ALL_ALL_NEIGHS

# enums
export Bug
export Gametype
export Direction

# methods
export set!
export remove!
export toggle!
export example
export start
export perft
export direction_from_string
export show
export get_hash_value
export fill_placement_locs_bb
export show_valid_actions
export show_pinned
export get_tile_from_string
export get_tile_info
export get_tile_name
export get_tile_height
export get_tile_bug
export get_tile_bug_num
export get_tile_color
export get_pinned_tiles!
export allneighs
export allneighs_view
export apply_direction
export action_from_move_string
export do_action
export validactions
export validactions!
export validactions_indices
export add_placements
export verify_perft
export isvalid_shifted_tile
export push_slidelocs!
export antmoves
export grasshoppermoves
export spidermoves
export beetlemoves
export ladybugmoves
export queenmoves
export pillbugmoves_normal
export pillbugmoves_throw
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

export BaseGame
export LGame
export PGame
export MGame
export MPGame
export MLGame
export LPGame
export MLPGame

# Game core files
include("game/enums.jl")
include("game/constants.jl")
include("game/structs.jl")
include("game/game.jl")
include("game/hex_set.jl")
include("main.jl")
include("game/show_methods.jl")
include("game/move_generation.jl")
include("game/perft.jl")
include("game/hash_values.jl")

# AI files
include("ai/search.jl")

end # module Intsect
