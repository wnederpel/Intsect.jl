
function get_tile_name_padded(tile, show_locs)
    if tile == EMPTY_TILE
        return " ⬡ "
    end
    name = get_tile_name(tile)

    if length(name) == 2
        name = " " * name
    end
    return name
end

function get_tile_name(tile)
    white, bug, bug_num, _ = get_tile_info(tile)
    name = ""
    if white == 1
        name *= "w"
    else
        name *= "b"
    end
    name *= BUG_NAMES[bug + 1]
    if bug < 4
        name *= string(bug_num + 1)
    end
    return name
end

function Base.show(board::Board, show_locs::Bool=false)
    println("-----------------")
    # somehow print this
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
    for row in 1:ROW_SIZE
        # Each name takes up 6 tokens
        # each new row should be 3 less indented
        print("  "^(ROW_SIZE - row))
        for col in 1:ROW_SIZE
            index = (row - 1) * ROW_SIZE + col
            tile = board.tiles[index]
            name = get_tile_name_padded(tile, show_locs)
            if show_locs
                if name == " ⬡ "
                    name = string(index - 1)
                    if length(name) == 1
                        name = " " * name
                    end
                    if length(name) == 2
                        name *= " "
                    end
                end
            end
            print("" * name * " ")
        end
        println("")
    end

    println()

    for nummed_bug in NUMMED_BUG_NAMES
        wpiece = "w" * nummed_bug
        bpiece = "b" * nummed_bug
        wloc = get_loc(board, get_tile_from_string(wpiece))
        bloc = get_loc(board, get_tile_from_string(bpiece))
        if wloc >= 0 && bloc >= 0
            println("$wpiece : $wloc \t $bpiece : $bloc")
        elseif wloc >= 0
            println("$wpiece : $wloc")
        elseif bloc >= 0
            println("\t\t $bpiece : $bloc")
        end
    end
    println("-----------------")

    return nothing
end

function Base.show(move::Move)
    println("Moving piece at loc $(move.moving_loc) to loc $(move.goal_loc)")
end

function Base.show(placement::Placement)
    name = get_tile_name(placement.tile)
    println("Placing piece $name at loc $(placement.goal_loc)")
end

function Base.show(tile::UInt8)
    println(get_tile_name(tile))
end

function Base.show(gamestring::GameString)
    println(
        gamestring.gametype *
        ";" *
        gamestring.gamestate *
        ";" *
        gamestring.player *
        gamestring.movestrings,
    )
end