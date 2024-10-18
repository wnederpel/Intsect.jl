using DataStructures
using Intsect

game = raw"wA1;bA1 wA1-;wQ -wA1;bQ bA1-;wB1 -wQ;bB1 bQ-;wB1 wB1-;bB1 -bB1"
movestrings = split(game, ';')

board = handle_newgame_command(Gametype.MLP)

for movestring in movestrings
    action = action_from_move_string(board, movestring)
    do_action(board, action)
    println("after move $movestring")
    show(board)
end

show(board)
actions = validactions(board)
show_valid_actions(board)