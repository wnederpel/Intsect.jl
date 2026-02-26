using Intsect

# Default settings
seconds_total = 2.0

# Create best move function
best_move_func = board -> get_best_move(board; time_limit_s=seconds_total, debug=true)

# Start the match player
start_match_player(best_move_func; gametype=MLPGame, starting_position=0)
