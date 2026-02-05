
function get_tile_name_padded(tile, show_locs)
    if tile == EMPTY_TILE
        return " ⬡ "
    end
    name = get_tile_name(tile)

    if length(name) == 2
        name = name * " "
    end
    return name
end

function get_tile_name(tile)
    if tile == EMPTY_TILE
        return "empty"
    end
    white, bug, bug_num, _ = get_tile_info(tile)
    name = ""
    if white == 1
        name *= "w"
    else
        name *= "b"
    end
    name *= BUG_NAMES[bug]
    if bug < 5
        name *= string(bug_num + 1)
    end
    return name
end

function show_valid_actions(board)
    show(validactions(board), board)
    return nothing
end

function Base.show(hs::HexSet, show_locs::Bool=true)
    for row in 1:ROW_SIZE
        # Each name takes up 6 tokens
        # each new row should be 3 less indented
        print("  "^(ROW_SIZE - row))
        for col in 1:ROW_SIZE
            loc = (row - 1) * ROW_SIZE + col - 1
            if hs[loc]
                name = " ⬣ "
            else
                name = ""
                if show_locs
                    name = string(loc)
                    if length(name) == 1
                        name = " " * name
                    end
                    if length(name) == 2
                        name *= " "
                    end
                else
                    name = " ⎔ "
                end
                name = "\e[2m" * name * "\e[0m"
            end
            print("" * name * " ")
        end
        println("")
    end
end

function show_pinned(board::Board, show_locs::Bool=true)
    for row in 1:ROW_SIZE
        # Each name takes up 6 tokens
        # each new row should be 3 less indented
        print("  "^(ROW_SIZE - row))
        for col in 1:ROW_SIZE
            loc = (row - 1) * ROW_SIZE + col - 1
            if board.ispinned[loc]
                name = " X "
            else
                name = ""
                if show_locs
                    name = string(loc)
                    if length(name) == 1
                        name = " " * name
                    end
                    if length(name) == 2
                        name *= " "
                    end
                else
                    name = " ⎔ "
                end
                name = "\e[2m" * name * "\e[0m"
            end
            print("" * name * " ")
        end
        println("")
    end
end

function Base.show(board::Board; show_locs::Bool=true, simple::Bool=false)
    println("-----------------")
    if !simple
        show(GameString(board))
    else
        for i in 1:(board.last_history_index)
            if i > 400
                println("... (truncated)")
                break
            end
            action = ALL_ACTIONS[board.history[i]]
            print(i, " ", action)
            if action isa Placement
                tile_name = get_tile_name(action.tile)
                print(" ", tile_name)
            end
            println()
        end
    end
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
            loc = (row - 1) * ROW_SIZE + col - 1
            tile = get_tile_on_board(board, loc)
            name = get_tile_name_padded(tile, show_locs)
            if name == " ⬡ "
                if show_locs
                    name = string(loc)
                    if length(name) == 1
                        name = " " * name
                    end
                    if length(name) == 2
                        name *= " "
                    end
                end
                name = "\e[2m" * name * "\e[0m"
            end
            print("" * name * " ")
        end
        println("")
    end

    println()

    for nummed_bug in NUMMED_BUG_NAMES
        wpiece = "w" * nummed_bug
        bpiece = "b" * nummed_bug
        wtile = get_tile_from_string(board, wpiece)
        btile = get_tile_from_string(board, bpiece)
        wloc = get_loc(board, wtile)
        bloc = get_loc(board, btile)
        wheight = get_tile_height(wtile)
        bleight = get_tile_height(btile)
        if wheight > 1
            wloc = string(wloc)
            wloc *= "^" * string(wheight)
        end
        if bleight > 1
            bloc = string(bloc)
            bloc *= "^" * string(bleight)
        end
        if wloc == UNDERGROUND
            wloc = (find_tile_in_underworld(board, wtile),)
        end
        if bloc == UNDERGROUND
            bloc = (find_tile_in_underworld(board, btile),)
        end
        if wloc != -1 && bloc != -1
            println("$wpiece : $wloc \t $bpiece : $bloc")
        elseif wloc != -1
            println("$wpiece : $wloc")
        elseif bloc != -1
            println("\t\t $bpiece : $bloc")
        end
    end
    println("-----------------")

    return nothing
end

function find_tile_in_underworld(board, tile)
    # Remove height information from the tile we're searching for
    tile_without_height = tile & 0xFC

    # Search through all locations
    for loc in 0:(GRID_SIZE - 1)
        # Check if this location has an underworld stack
        if haskey(board.underworld, loc)
            stack = board.underworld[loc]
            # Search through the stack from bottom to top
            for (depth, stacked_tile) in enumerate(stack)
                stacked_tile_without_height = stacked_tile & 0xFC
                if stacked_tile_without_height == tile_without_height
                    return loc
                end
            end
        end
    end

    # Tile not found in underworld
    return nothing
end

function Base.show(actions::Vector{Action}, board)
    println(string(length(actions)) * " valid actions:")
    for (i, action) in enumerate(actions)
        print("$i: ")
        show(action, board)
    end
    println("End")
    return nothing
end

function Base.show(move::Move, board::Board)
    println("Move: " * move_string_from_action(board, move))
    return nothing
end

function Base.show(placement::Placement, board::Board)
    println("Placement: " * move_string_from_action(board, placement))
    return nothing
end

function Base.show(climb::Climb, board::Board)
    println("Climb: " * move_string_from_action(board, climb))
    return nothing
end

function Base.show(pass::Pass, board::Board)
    println("Pass")
    return nothing
end

function Base.show(tile::UInt8)
    println(get_tile_name(tile))
    return nothing
end

function gamestring_to_string(gamestring::GameString)
    return nothing
    return gamestring.gametype *
           ";" *
           gamestring.gamestate *
           ";" *
           gamestring.player *
           gamestring.movestrings
end

function Base.show(gamestring::GameString)
    println(gamestring_to_string(gamestring))
    return nothing
end