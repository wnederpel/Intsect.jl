@enumx Gametype begin
    Base
    M
    L
    P
    ML
    MP
    LP
    MLP
end

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

@generated function filter_bugs(bug_list::AbstractVector, gametype)
    if gametype == Gametype.Base
        return :((x for x in bug_list))
    elseif gametype == Gametype.M
        return :((x for x in bug_list if x ∉ (Integer(Bug.MOSQUITO))))
    elseif gametype == Gametype.L
        return :((x for x in bug_list if x ∉ (Integer(Bug.LADYBUG))))
    elseif gametype == Gametype.P
        return :((x for x in bug_list if x ∉ (Integer(Bug.PILLBUG))))
    elseif gametype == Gametype.LP
        return :((x for x in bug_list if x ∉ (Integer(Bug.PILLBUG), Integer(Bug.LADYBUG))))
    elseif gametype == Gametype.MP
        return :((x for x in bug_list if x ∉ (Integer(Bug.MOSQUITO), Integer(Bug.PILLBUG))))
    elseif gametype == Gametype.ML
        return :((x for x in bug_list if x ∉ (Integer(Bug.MOSQUITO), Integer(Bug.LADYBUG))))
    elseif gametype == Gametype.MLP
        return :((
            x for
            x in bug_list if x ∉ (Integer(Bug.MOSQUITO), Integer(Bug.PILLBUG), Integer(Bug.LADYBUG))
        ))
    end
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