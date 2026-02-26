using Intsect
using PProf: PProf
using Profile: Profile

board = handle_newgame_command(MLPGame)

board = from_game_string(
    raw"Base+MLP;InProgress;White[10];wL;bL wL\;wA1 \wL;bM bL\;wQ /wA1;bA1 /bL;wA1 bM-;bQ bA1\;wA2 \wL;bA1 \wA2;wQ /wL;bS1 /bQ;wM /wA2;bS1 /wQ;wP -wM;bA1 wA2/;wA1 bM\;bQ /wA1",
)

time_limit_s = 0.01

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