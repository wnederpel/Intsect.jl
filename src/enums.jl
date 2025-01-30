abstract type Gametype end

struct BaseGame <: Gametype end
struct MGame <: Gametype end
struct LGame <: Gametype end
struct PGame <: Gametype end
struct MLGame <: Gametype end
struct MPGame <: Gametype end
struct LPGame <: Gametype end
struct MLPGame <: Gametype end

# TODO speed: maybe replace with a named tuple
@enumx Bug::UInt8 begin
    ANT = 1         # 3
    GRASSHOPPER = 2 # 3
    BEETLE = 3      # 2
    SPIDER = 4      # 2
    QUEEN = 5       # 1
    LADYBUG = 6     # 1
    MOSQUITO = 7    # 1
    PILLBUG = 8     # 1
end

# TODO speed: maybe replace with a named tuple
@enumx Direction::UInt8 begin
    NW
    NE
    E
    SE
    SW
    W
end