
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

function Base.show(bb::BitBoard, show_locs::Bool=true)
    for row in 1:ROW_SIZE
        # Each name takes up 6 tokens
        # each new row should be 3 less indented
        print("  "^(ROW_SIZE - row))
        for col in 1:ROW_SIZE
            loc = (row - 1) * ROW_SIZE + col - 1
            if bb[loc]
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
            if board.ispinned[loc + 1]
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

function Base.show(board::Board; show_locs::Bool=true, simple::Bool=true)
    println("-----------------")
    if !simple
        show(GameString(board))
    else
        for i in 1:(board.last_history_index)
            action = ALL_ACTIONS[board.history[i]]
            print(i, " ", ALL_ACTIONS[board.history[i]])
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
        wloc = get_loc(board, get_tile_from_string(board, wpiece))
        bloc = get_loc(board, get_tile_from_string(board, bpiece))
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

function Base.show(gamestring::GameString)
    println(
        gamestring.gametype *
        ";" *
        gamestring.gamestate *
        ";" *
        gamestring.player *
        gamestring.movestrings,
    )
    return nothing
end