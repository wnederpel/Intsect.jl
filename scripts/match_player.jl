using Intsect

# Default settings
depth = 4
time_limit = 10.0
gametype = MLPGame
starting_position = 0

# Create best move function
best_move_func = board -> get_best_move(board, depth, time_limit)

# Start the match player
start_match_player(best_move_func; gametype=gametype, starting_position=starting_position)
