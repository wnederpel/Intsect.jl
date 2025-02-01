using Intsect

board = handle_newgame_command(BaseGame)
# Place some pieces
movestrings = [
    raw"wA1",
    raw"bA1 wA1-",
    raw"wQ /wA1",
    raw"bQ bA1/",
    raw"wG1 \wQ",
    raw"bG1 bQ\\",
    raw"wB1 \wA1",
    raw"bB1 bA1\\",
    raw"wS1 wQ\\",
    raw"bS1 \bQ",
]
gamestring = raw"Base;InProgress;white[6];wA1;bA1 wA1-;wQ /wA1;bQ bA1/;wG1 \wQ;bG1 bQ\;wB1 \wA1;bB1 bA1\;wS1 wQ\;bS1 \bQ"

for movestring in movestrings
    do_action(board, movestring)
end

show(board)

Intsect.perft(1, board) |> println
Intsect.perft(2, board) |> println
Intsect.perft(3, board) |> println
Intsect.perft(4, board) |> println
Intsect.perft(5, board) |> println
# @assert Intsect.perft(1, board) == 37
# @assert Intsect.perft(2, board) == 1358
# @assert Intsect.perft(3, board) == 57612
# @assert Intsect.perft(4, board) == 2417137
# @assert Intsect.perft(5, board) == 114983055