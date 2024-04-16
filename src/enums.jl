@enumx Gametype begin
    MLP
end

# TODO speed: maybe replace with a named tuple
@enumx Bug::UInt8 begin
    ANT = 0         # 3
    GRASSHOPPER = 1 # 3
    BEETLE = 2      # 2
    SPIDER = 3      # 2
    QUEEN = 4       # 1
    LADYBUG = 5     # 1
    MOSQUITO = 6    # 1
    PILLBUG = 7     # 1
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