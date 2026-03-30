using Intsect
using PProf: PProf
using Profile: Profile

time_limit = 0.01
debug = false
full_debug = false

Arenant.run_arena(; debug=debug, time_limit_s=time_limit, full_debug=full_debug)

# Profile.clear()
# Profile.@profile Arenant.run_arena(; debug=debug, time_limit_s=time_limit, full_debug=full_debug)
# PProf.pprof()

# Arenant.play_one_match(
#     "engines\\source",
#     "engines\\nokamute.exe",
#     # "engines\\intsect-first-release.bat",
#     time_limit;
#     starting_position=raw"wL;bL wL\;wA1 \wL;bM bL\;wQ /wA1;bA1 /bL;wA1 bM-;bQ bA1\\",
#     debug=debug,
# )