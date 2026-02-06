using Intsect

time_limit = 0.05
debug = true
Arenant.run_arena(; debug=debug, time_limit_s=time_limit)
# Arenant.play_one_match(
#     "engines\\source",
#     "engines\\MzingaEngine.exe",
#     # "engines\\intsect-first-release.bat",
#     time_limit;
#     starting_position=raw"wL;bL wL\;wA1 \wL",
#     debug=debug,
# )