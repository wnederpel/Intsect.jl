using Intsect
using PProf: PProf
using Profile: Profile

board = handle_newgame_command(MLPGame)

board = from_game_string(
    raw"Base+MLP;InProgress;White[13];wG1;bA1 wG1-;wA1 /wG1;bS1 bA1-;wA2 wA1\;bQ \bS1;wQ -wG1;bG1 bS1-;wA2 bG1/;bB1 bA1\;wA1 \bQ;bA2 bS1\;wB1 -wA1;bA2 /wQ;wA3 \wA1;bS2 /bA2;wA3 bQ/;bA3 bS1\;wB1 wA1;bA3 wA2/;wB2 \wA3;bS2 \wQ;wB2 wA3;bA3 \wG1",
)

time_limit_s = 1

best_action = get_best_move(board; time_limit_s=time_limit_s, debug=true)

# best_action = get_best_move(board; time_limit_s=time_limit_s, debug=true)

# Profile.clear()
# Profile.@profile get_best_move(board; time_limit_s=time_limit_s, debug=false)
# PProf.pprof()

# Profile.Allocs.clear()
# Profile.Allocs.@profile sample_rate = 0.01 get_best_move(
#     board; time_limit_s=time_limit_s, debug=false
# )
# PProf.Allocs.pprof()

show(board)
println("^^ board before move ^^")