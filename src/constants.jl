
# Board representation: wrapping grid of tile locations.
# Rows wrap around, and each row wraps to the next row.
# It's like a spiral around a torus.

# A 4x4 example: NOTE 4x4, not 16x16

#         11  12  13  14  15
#           \ / \ / \ / \ /
#       15 - 0 - 1 - 2 - 3 - 4
#         \ / \ / \ / \ / \
#      3 - 4 - 5 - 6 - 7 - 8
#       \ / \ / \ / \ / \
#    7 - 8 - 9 -10 -11 -12
#     \ / \ / \ / \ / \
# 11 -12 -13 -14 -15 - 0
#     / \ / \ / \ / \
#    0   1   2   3   4
# Even the 16 x 16 might be way too small. 
# Each side as 14 pieces, so everything in a straight line would require
# 28 * 28 = 784 pieces.
const ROW_SIZE::Int = 8
const GRID_SIZE::Int = ROW_SIZE * ROW_SIZE
const MID::Int = (ROW_SIZE + 1) * Int(floor(ROW_SIZE / 2))

const BUG_NUM_MASK::UInt8 = 0b11000000
const BUG_NUM_SHIFT::UInt8 = 6
const BUG_MASK::UInt8 = 0b00111000
const BUG_SHIFT::UInt8 = 3
const COLOR_MASK::UInt8 = 0b00000100
const COLOR_SHIFT::UInt8 = 2
const HEIGHT_MASK::UInt8 = 0b00000011
const HEIGHT_SHIFT::UInt8 = 0

const INDEX_SHIFT::UInt8 = 2
const EMPTY_TILE::UInt8 = 0b11111111
const NOT_PLACED::Int = -1
const INVALID_LOC::Int = -2

const WHITE::Int = 1
const BLACK::Int = 0
const DRAW::Int = 2
const NO_COLOR::Int = 3

# For now these are global constants, later make this configurable if that's interesting
const BUGS_IN_PLAY::Int = 8
const TOTAL_NUM_BUGS::Int = 14
const GAMETYPE::Gametype.T = Gametype.MLP

const BUG_NAMES = ["A", "G", "B", "S", "Q", "L", "M", "P"]
const NUMMED_BUG_NAMES = [
    "A1", "A2", "A3", "G1", "G2", "G3", "B1", "B2", "S1", "S2", "Q", "L", "M", "P"
]
