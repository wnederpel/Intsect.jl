using Intsect

game = raw"wA1;bA1 \wA1;wQ wA1-;bQ bA1/;wP wQ/;bP bQ/"
movestrings = split(game, ';')

board = handle_newgame_command(Gametype.MLP)

const actions = foreach(
    movestring -> begin
        action = action_from_move_string(board, movestring)
        do_action(board, action)
    end, movestrings
)

show(board)

my_adj = board.white_pieces

my_adj =
    my_adj |
    bitrotate(my_adj, 1) |
    bitrotate(my_adj, -1) |
    bitrotate(my_adj, ROW_SIZE) |
    bitrotate(my_adj, -ROW_SIZE) |
    bitrotate(my_adj, ROW_SIZE + 1) |
    bitrotate(my_adj, -ROW_SIZE - 1)

show(my_adj)

show(get_adjacent_bb(board.white_pieces))
