using Intsect

time_limit = 0.1
debug = false
Arenant.run_arena(; debug=debug, time_limit_s=time_limit)
Arenant.play_one_match(
    "engines\\MzingaEngine.exe",
    "engines\\source",
    time_limit;
    starting_position=raw"wL;bL wL\;wA1 \wL",
    debug=debug,
)