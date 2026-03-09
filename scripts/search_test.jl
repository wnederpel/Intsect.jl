using Intsect
using PProf: PProf
using Profile: Profile

board = handle_newgame_command(MLPGame)

board = from_game_string(raw"Base;InProgress;White[13]")

time_limit_s = 0.5

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