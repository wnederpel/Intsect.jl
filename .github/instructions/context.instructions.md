---
description: "Use when wanting to get to know some details about the code base. The AI search and evaluation are under development so the information could be outdated."
applyTo: "src/**"
---
## **INTSECT HIVE GAME ENGINE - DETAILED RESEARCH**

### **1. BOARD STRUCT - All Fields**

[Board struct in src/game/structs.jl](src/game/structs.jl#L154)

```julia
mutable struct Board
    # Core tile representation
    tiles::MVector{GRID_SIZE,UInt8}              # All tiles on board (256 locations)
    tile_locs::MVector{36,Int}                   # Location of each tile (indexed by tile >> 2)
    
    # Game state
    just_moved_loc::Int                          # Location of piece that just moved
    current_color::UInt8                         # WHITE(1) or BLACK(2)
    queen_placed::MVector{2,Bool}                # Has queen been placed? [white, black]
    ply::UInt16                                  # Total half-moves played
    turn::Int                                    # Full turns (increments when white moves)
    gameover::Bool                               # Is game finished?
    victor::Int                                  # NO_COLOR, WHITE, BLACK, or DRAW
    
    # Move history
    history::MVector{HISTORY_BUFFER_SIZE,Int}   # Action indices of all moves (600 deep)
    last_history_index::Int                     # Current position in history
    hash_history::MVector{HISTORY_BUFFER_SIZE,UInt}  # Zobrist hashes for draw detection
    hash_history_index::Int                     # Current position in hash_history
    
    # 3D board representation (stacked pieces)
    underworld::DefaultDict{Int,Stack{UInt8}}   # Buried tiles under climbers
    
    # Valid actions buffer
    validactions::MVector{VALID_BUFFER_SIZE,Int>  # Cached valid action indices (400)
    action_index::Int                           # Current position in validactions
    
    # Tile availability
    placeable_tiles::SVector{2,MVector{8,UInt8}} # Next available tile for each bug [white, black]
    
    # Movement constraints
    ispinned::HexSet                             # Which pieces are pinned? (articulation points)
    pieces::SVector{2,HexSet}                    # Which locations have [white, black] pieces
    
    # Search/state tracking
    last_moves::Vector                           # Ring buffer of recent moves
    last_moves_index::Int                        # Position in ring buffer
    general_pinned_update_required::Bool         # Flag for lazy pinned computation
    queen_pos_white::Int                         # Location of white queen (-1 if not placed)
    queen_pos_black::Int                         # Location of black queen (-1 if not placed)
    
    # Zobrist hashing
    hash::UInt64                                 # Base board hash (without color/just_moved)
    location_hash::UInt64                        # Hash for sliding movement (location only)
    
    # Transposition tables
    move_store::Vector{MoveStoreEntry}           # 4MB cache: ant reachable sets
    pinned_store::Vector{PinnedStoreEntry}       # 4MB cache: pinned pieces
    search_store::Vector{SearchStoreEntry}       # 64MB cache: transposition table
    
    # Principal Variation
    pv_store::MVector{PV_STORE_SIZE,MVector{PV_STORE_SIZE,Int32>>  # (30×30) PV table
    
    # Workspace buffers for move generation
    workspaces::Workspaces                       # Reusable HexSets for algorithms
    
    # Game configuration
    gametype::Type{<:Gametype}                   # Which bugs are in play?
end
```

### **2. TILE ENCODING**

Tiles encoded as **UInt8** with this bit layout:

```
bits 6-7: BUG_NUM (0-3, which instance: A1=0, A2=1, A3=2, G1=0, G2=1, G3=2, Q=0, etc.)
bits 3-5: BUG (2^3-1 = 0-7, Bug enum: ANT=1, GRASSHOPPER=2, BEETLE=3, SPIDER=4, QUEEN=5, LADYBUG=6, PILLBUG=7, MOSQUITO=8)
bit 2:    COLOR (0=WHITE, 1=BLACK... wait, actually (value >> COLOR_SHIFT) + 0x01 → 1 or 2)
bits 0-1: HEIGHT (0=ground, 1, 2, 3+; read from underworld for exact)
```

**Constants:**
```julia
const BUG_NUM_MASK::UInt8 = 0b11000000
const BUG_NUM_SHIFT::UInt8 = 6
const BUG_MASK::UInt8 = 0b00111000
const BUG_SHIFT::UInt8 = 3
const COLOR_MASK::UInt8 = 0b00000100
const COLOR_SHIFT::UInt8 = 2
const HEIGHT_MASK::UInt8 = 0b00000011
const HEIGHT_SHIFT::UInt8 = 0
const EMPTY_TILE::UInt8 = 0b11111111
const NOT_PLACED::Int = -1
const INVALID_LOC::Int = -2
const UNDERGROUND::Int = -3
```

**Tile Functions:**
- `get_tile_color(tile)` → WHITE(1) or BLACK(2)
- `get_tile_bug(tile)` → Bug enum (1-8)
- `get_tile_bug_num(tile)` → 0-based number (0=first, 1=second, etc.)
- `get_tile_height(tile)` → 1-based height (1, 2, 3+; 0 for EMPTY_TILE)
- `tile_from_info(color, bug, bug_num; height=0)` → UInt8 tile
- `get_tile_info(tile)` → (color, bug, bug_num, height)

### **3. GAME GRID & NEIGHBOR LOOKUP**

**Board Layout:**
- 16×16 hex grid (256 locations, 0-indexed)
- Wraps on edges (toroidal topology)
- Indexed linearly: `loc = row * ROW_SIZE + col`

```julia
const GRID_SIZE::Int = 256
const ROW_SIZE::Int = 16
const MID::Int = 136  # Center location

# Precomputed neighbor lookup
const ALL_ALL_NEIGHS::SVector{GRID_SIZE,Tuple{Int,Int,Int,Int,Int,Int}}

@inline function allneighs(loc) → (ne, se, s, sw, nw, n)  # 6 neighbors in order
@inline function are_neighs(loc1, loc2) → Bool
```

**Directions (hexagonal):**
```julia
@enum Direction.T begin
    NW = 0, NE = 1, E = 2, SE = 3, SW = 4, W = 5
end

function apply_direction(loc, dir) → neighbor_loc
```

### **4. ENUMS & CONSTANTS**

**Bugs (in play order):**
```julia
@enumx Bug::UInt8 begin
    ANT = 1         # 3 available
    GRASSHOPPER = 2 # 3 available
    BEETLE = 3      # 2 available
    SPIDER = 4      # 2 available
    QUEEN = 5       # 1 available
    LADYBUG = 6     # 1 available (expansion)
    PILLBUG = 7     # 1 available (expansion)
    MOSQUITO = 8    # 1 available (expansion)
end

const MAX_NUMS::SVector{8,UInt8} = [2, 2, 1, 1, 0, 0, 0, 0]  # Max 0-based bug number
```

**Game Types (variants):**
```julia
abstract type Gametype end
struct BaseGame <: Gametype end  # Ant, Grasshopper, Beetle, Spider, Queen only
struct MGame <: Gametype end     # + Mosquito
struct LGame <: Gametype end     # + Ladybug  
struct PGame <: Gametype end     # + Pillbug
struct MLGame <: Gametype end    # + Mosquito + Ladybug
struct MPGame <: Gametype end    # + Mosquito + Pillbug
struct LPGame <: Gametype end    # + Ladybug + Pillbug
struct MLPGame <: Gametype end   # + all three
```

**Colors:**
```julia
const WHITE::UInt8 = 1
const BLACK::UInt8 = 2
const DRAW::UInt8 = 3
const NO_COLOR::UInt8 = 4
```

### **5. HEX_SET OPERATIONS**

Efficient set of hexagon locations using bitwise operations (16 words × 64 bits = 1024 bits for 256 locations):

```julia
struct HexSet
    table::MVector{4,UInt64}  # 4 × 64-bit words cover 256 locations
end

# Operations (all O(1) or O(words))
remove!(hs, loc)           # Remove location from set
set!(hs, loc)              # Add location to set
toggle!(hs, loc)           # Toggle location
get(hs, loc) → Bool        # Check if location in set
clear!(hs)                 # Clear all locations
union!(hs1, hs2)           # hs1 |= hs2
overwrite!(hs1, hs2)       # hs1 = copy(hs2)
for_each_bit_set(f, hs)    # Iterate over set locations
count_ones(hs) → Int       # Cardinality
```

### **6. BITBOARD OPERATIONS (Not Currently Used)**

Appears to have been planned but the codebase uses HexSet instead:

```julia
struct BitBoard
    x1::UInt64  # Locations 0-63
    x2::UInt64  # Locations 64-127
    x3::UInt64  # Locations 128-191
    x4::UInt64  # Locations 192-255
end

# Operations: &, |, ~, >>>, <<, bitrotate
get_bb(loc) → BitBoard          # Single bit set at location
get_neigh_bb(loc) → BitBoard    # 6 neighbors set
get_adjacent_bb(bb) → BitBoard  # All neighbors of all set bits
```

### **7. ACTION TYPES**

```julia
abstract type Action end

struct Move <: Action
    moving_loc::Int   # Source location
    goal_loc::Int     # Destination (must be empty or stacked)
end

struct Placement <: Action
    goal_loc::Int     # Placement location
    tile::UInt8       # Tile being placed
end

struct Climb <: Action
    moving_loc::Int   # Source location
    goal_loc::Int     # Destination (has other tile on it)
end

struct Pass <: Action
    goal_loc::Int     # INVALID_LOC (unused for pass)
end
```

**Action Index/Lookup System:**

Actions are uniquely indexed integers for fast transposition table lookups:

```julia
const MAX_PLACEMENT_INDEX::Int32 = GRID_SIZE * 36          # ~9216
const MAX_MOVEMENT_INDEX::Int32 = GRID_SIZE * GRID_SIZE   # ~65536
const MAX_CLIMB_INDEX::Int32 = GRID_SIZE * GRID_SIZE      # ~65536

# Functions to convert between actions and indices
action_index(action::Action) → Int32              # Get index
action_type(action_as_index) → Type               # Get action type
do_for_action(idx, f) → f(action)                 # Dispatch to action

# Constants
const ALL_PLACEMENTS::Vector{Placement}           # All ~9216 possible placements
const ALL_MOVEMENTS::Vector{Move}                 # All ~65536 possible moves
const ALL_CLIMBS::Vector{Climb}                   # All ~65536 possible climbs
const ALL_ACTIONS::Vector{Action}                 # Combined vector
const pass_index()::Int32 → PASS_INDEX_OFFSET     # Special index for Pass
```

### **8. MOVE GENERATION SYSTEM**

[move_generation.jl](src/game/move_generation.jl)

**Entry point:**
- `validactions(board) → Vector{Action}` - Get all legal moves

**Internal workflow:**
1. `validactions!()`, `validactions_indices()` - Populate move buffer
2. Dispatch based on game phase:
   - **Turn 4 (forced queen placement):** `queenplacements()`
   - **Turn 1-2 (initial placement):** `firstplacements()`, `secondplacements()`
   - **General case:** `validactions_general()` which calls:
     - `add_moves()` - All sliding/hopping moves for placed pieces
     - `add_placements()` - All valid placement locations

**Move Generation Details:**

**For each bug type:**
```julia
# Bug-specific move generators (called from bugmoves)
antmoves(board, loc, move_to_set)               # Fill reachable (flood fill)
grasshoppermoves(board, loc, move_to_set)       # Jump over neighbors in 6 directions
beetlemoves(board, loc, height, move_to_set)    # Can stack or slide
spidermoves(board, loc, move_to_set)            # Move exactly 3 slides
queenmoves(board, loc, move_to_set)             # Move exactly 1 slide
ladybugmoves(board, loc, move_to_set)           # 3-step: up, over 2, down (must clear path)
pillbugmoves_normal(board, loc, move_to_set)    # Move 1, or move adjacent piece
pillbugmoves_throw(board, loc, ispinned, from, to)  # Throw adjacent pieces
mosquitomoves(board, loc, height, ispinned, move_to_set) # Mimic adjacent bugs
```

**Sliding mechanics:**
```julia
@inline function canslide(i, board, neighlocs) → Bool
    # Can move in direction i if:
    # 1. Direction itself is empty
    # 2. At least one neighbor perpendicular is empty
    
@inline function get_slide_neighs(board, all_neighbours) → UInt (bit mask)
    # Returns 6 bits indicating which directions are slidable
```

**Pinned piece detection:**
Uses articulation point algorithm (cut vertices in graph):
```julia
update_ispinned_general!(board)
get_pinned_tiles_general!(board, visited, depth, low, parent, loc, depth)
```

**Move ordering for placements:**
```julia
for_placement_locs(f, board, color)
    # Marks all placement locations and calls f for each
    # Must be adjacent to own pieces, not adjacent to opponent
```

### **9. SUGGESTED ACTIONS**

[src/ai/suggested_actions.jl](src/ai/suggested_actions.jl)

Tracks which actions are "suggested" (e.g., from previous iterations or known good moves):

```julia
mutable struct SuggestedActions
    index::Int
    actions::Array{Int32,1}        # Buffer of suggested action indices
    moving_loc_hs::HexSet          # Source locations that have suggested moves
    goal_loc_hs::HexSet            # Target locations that have suggested moves
end

add!(sa, action_index)             # Add action to suggestion set
contains(action_index, sa) → Bool  # Check if action is suggested
```

Used in search to try promising moves first (killer moves, PV moves, etc.)

### **10. SEARCH ALGORITHM**

[src/ai/search.jl](src/ai/search.jl)

**Entry point:**
```julia
get_best_move(board; depth=5000, time_limit_s=10.0, debug=true) → Action
```

**Framework:**
```julia
iterative_deepening(board, ply, timeout, max_depth, nodes_processed, debug)
    → minimax with increasing depths
```

**Core search:**
```julia
minimax(
    board, ply, timeout, depth, initial_depth, 
    extension_budget, buffer_idx, nodes_processed, debug,
    pv_move, killer_table;
    suggested_moves_array, alpha, beta, pv_node
) → Float32 score
```

**Key components:**

1. **Transposition Table (Search Store):**
   ```julia
   struct SearchStoreEntry
       full_hash::UInt64          # Full board hash
       score::Float32             # Cached score
       depth::Int32               # Depth of this entry
       action_chosen::Int32       # Best action found
       type::Symbol               # :exact, :lowerbound, :upperbound
       refutation_move::Int32     # Move that refutes this
   end
   ```

2. **Killer Moves (same-side cutoffs):**
   ```julia
   struct KillerTable
       moves::Matrix{Int32}       # [MAX_KILLER_PLY × 2]
   end
   
   store_killer!(kt, ply, move)
   is_killer(kt, ply, move) → Bool
   ```

3. **Move Ordering (order_moves! function):**
   ```julia
   order_moves!(ordered_buffer, board, move_buffer, last_best_move,
               suggested_moves, killer_table, ply,
               good_buffer, normal_buffer, bad_buffer, ...)
       → idx (number of ordered moves)
   ```
   
   **Ordering priority:**
   1. Last best move from PV (transposition table)
   2. Suggested moves (from previous iteration or analysis)
   3. Killer moves (same ply or ply-2)
   4. Good moves (Ant/Mosquito movements)
   5. Normal moves (Queen, Ladybug, Pillbug, Spider climbs)
   6. Bad moves (Grasshopper, piece placements)

4. **Principal Variation:**
   ```julia
   pv_store::MVector{30,MVector{30,Int32>>     # PV matrix
   ```
   Stores best sequence of moves at each depth

5. **Alpha-Beta Pruning:**
   - Negamax framework (negate scores between plies)
   - Beta cutoff triggers killer move storage
   - PV nodes tracked separately for better move ordering

### **11. EVALUATION FUNCTION**

[src/ai/evaluate.jl](src/ai/evaluate.jl)

```julia
evaluate_board(board) → Float32
```

**Evaluation components:**

1. **Queen Safety** (scaled by ply):
   ```julia
   evaluate_queen_safety(board, color, queen_loc) → Float32
       Factors:
       - Empty spots around queen (+2 each, max 12)
       - Friendly pieces adjacent:
         - Pillbug (+20, essential for moving queen)
         - Mosquito mimicking pillbug (+20)
         - Pinned friendly piece (-5)
       - Enemy pieces adjacent (-3)
       - Enemy climber on queen (-10 extra)
       - Other color piece on top of queen (-5 × free_spots)
       - Pinned queen (-3)
   ```

2. **Top of Hive Score:**
   ```julia
   top_of_hive_score(board) → Float32
       - Each beetle on top: +2
       - Beetle near enemy queen: +8 (threatening)
       - Beetle near own queen: +2 (defending)
       Negated for opponent's pieces
   ```

3. **Piece Freedom** (unpinned mobile pieces):
   ```julia
   piece_freedom_score(board, color) → Float32
       Bug values (when unpinned):
       - Ant: 13.0 (most mobile)
       - Beetle: 12.0
       - Ladybug: 6.0
       - Queen: 2.5
       - Pillbug: 1.5
       - Spider/Grasshopper: 0.5 (least mobile)
       
       Penalties:
       - Pinned beetle on ground: -3.0 (very bad)
       - Single enemy neighbor: 50% discount
       - Surrounded (5+ neighbors): value zeroed
   ```

4. **Pieces in Hand Penalty:**
   ```julia
   pieces_in_hand_penalty(board, color) → Float32
       Early game penalties for not placing strong pieces:
       - Ants: -0.5 × count × ramp(ply/10, 0→2)
       - Mosquito: -0.5 × ramp(ply/8, 0→2.5)
       - Pillbug: -0.4 × ramp(ply/10, 0→2)
       - Beetles: -0.4 × count × max(0, ramp(ply-16, 0→1.5))
   ```

**Score normalization:**
- Always from current player's perspective
- If current player is BLACK, negate score

### **12. DO/UNDO SYSTEM**

[src/game/game.jl](src/game/game.jl#L545)

**Execute action:**
```julia
do_action(board, action::Action)
    → pre_action_update()
    → modify board (tiles, locations, underworld)
    → post_action_update()
```

**Specific implementations:**
```julia
do_action(board, placement::Placement)
do_action(board, move::Move)
do_action(board, climb::Climb)  # Handle stacking/underworld
do_action(board, pass::Pass)
```

**State updates:**
```julia
pre_action_update(board, action)
    - Increment last_history_index
    - Store action index in history
    
post_action_update(board, action)
    - Update hex sets (pieces[color])
    - Update Zobrist hash
    - Update just_moved_loc
    - Update ply/turn/current_color
    - Check gameover (queen surrounded)
    - Check draw (3-fold repetition)
```

**Undo:**
```julia
undo(board)
    → undo_action(board, last_action_from_history)
    → inverse all updates
```

### **13. CACHING & STORES**

**Move Store (4MB, 4096 entries):**
Caches reachable squares for ant from each position
```julia
struct MoveStoreEntry
    location_hash::UInt64          # Hash of piece positions
    ant_reachable_hs::HexSet       # Ant reachable from location
end
```

**Pinned Store (4MB, 4096 entries):**
Caches pinned pieces by position
```julia
struct PinnedStoreEntry
    location_hash::UInt64
    pinned_pieces_hs::HexSet
end
```

**Search Store (64MB, 65536 entries):**
Main transposition table
```julia
struct SearchStoreEntry
    full_hash::UInt64
    score::Float32
    depth::Int32
    action_chosen::Int32
    type::Symbol               # :exact, :lowerbound
    refutation_move::Int32
end
```

### **14. ZOBRIST HASHING**

```julia
get_hash_value(board) → UInt64
    = board.hash (piece positions)
    ⊕ COLOR_HASH if BLACK to move
    ⊕ just_moved location hash if same color's piece

board.hash      # Base hash (piece positions only)
board.location_hash  # Hash of occupied locations (for sliding)

get_hash_value(tile, loc; height=0) → UInt64
    # Look up in precomputed HASH_VALUES table
    
HASH_VALUES[1 + (tile >> INDEX_SHIFT) + height*36 + loc*36*7]
    # 256 locations × 36 tiles × 7 heights
```

### **15. HELPER FUNCTIONS**

**Neighbor connectivity:**
```julia
allneighs(loc) → Tuple{Int,Int,Int,Int,Int,Int}  # 6 neighbors
are_neighs(loc1, loc2) → Bool                     # Are adjacent?

has_one_neigh_and_get(board, loc; skip_loc) → (Bool, loc)
    # Check if exactly one non-empty neighbor
```

**Location utilities:**
```julia
apply_direction(loc, direction) → neighbor_loc
get_location_hash_value(loc) → UInt64
```

**Tile management:**
```julia
get_tile_on_board(board, loc) → UInt8
set_tile_on_board(board, loc, tile)
get_loc(board, tile) → Int                        # Where is tile?
set_loc(board, tile, location)                    # Update tile location
```

**Board creation/conversion:**
```julia
handle_newgame_command(gametype) → Board
from_game_string(game_string) → Board
move_string_from_action(board, action) → String
action_from_move_string(board, string) → Action
```

---

**This architecture provides:**
- ✅ Efficient 256-location hex grid
- ✅ HexSet-based bitwise piece tracking
- ✅ Zobrist hashing for fast state comparison
- ✅ Complex move generation (8 bug types, stacking, special moves)
- ✅ Alpha-beta with killer moves & transposition tables
- ✅ PV-based iterative deepening
- ✅ Multi-component evaluation (queen safety, piece freedom, material)