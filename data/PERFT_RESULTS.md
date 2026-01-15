### First test with perft

Perft(0) = 1
time per node = 1.08e-5
Perft(1) = 7
time per node = 3.984285714285714e-5
Perft(2) = 294
time per node = 1.931530612244898e-5
Perft(3) = 6678
time per node = 4.495976340221623e-5
Perft(4) = 151686
time per node = 2.1244595414210935e-5

### Only update history for non simulated moves

Perft(0) = 1
time per node = 5.8e-6
memory per node = 3344 bytes
gc time  = 0.0

Perft(1) = 7
time per node = 2.2671428571428573e-5
memory per node = 4507 bytes
gc time  = 0.0

Perft(2) = 294
time per node = 1.1095918367346938e-5
memory per node = 4368 bytes
gc time  = 0.0

Perft(3) = 6678
time per node = 1.0795163222521713e-5
memory per node = 4581 bytes
gc time  = 0.0

Perft(4) = 151686
time per node = 1.2541246390569994e-5
memory per node = 4589 bytes
gc time  = 0.1207167

### Make parallel, but also add history back into the struct, this seems to add a lot of allocations

Perft(0) = 1
KN/S = 156.25
memory per node = 11808 bytes
gc time  = 0.0%
total time = 6.4e-6 seconds

Perft(1) = 7
KN/S = 16.62
memory per node = 14366 bytes
gc time  = 0.0%
total time = 0.0004213 seconds

Perft(2) = 294
KN/S = 167.45
memory per node = 12924 bytes
gc time  = 0.0%
total time = 0.0017558 seconds

Perft(3) = 6678
KN/S = 251.15
memory per node = 13081 bytes
gc time  = 0.0%
total time = 0.0265901 seconds

Perft(4) = 151686
KN/S = 244.23
memory per node = 13099 bytes
gc time  = 0.0%
total time = 0.6210779 seconds

### Remove history from the struct, and go to perft 5, although it is not correct, lot of gc time

Perft(0) = 1
KN/S = 0.01
memory per node = 812048 bytes
gc time  = 0.0%
total time = 0.0806565 seconds

Perft(1) = 7
KN/S = 0.0
memory per node = 30556509 bytes
gc time  = 2.35%
total time = 1.5599508 seconds

Perft(2) = 294
KN/S = 234.6
memory per node = 4428 bytes
gc time  = 0.0%
total time = 0.0012532 seconds

Perft(3) = 6678
KN/S = 71.32
memory per node = 5496 bytes
gc time  = 0.0%
total time = 0.0936284 seconds

Perft(4) = 151686
KN/S = 404.79
memory per node = 4603 bytes
gc time  = 2.64%
total time = 0.3747254 seconds

Perft(5) = 5541678
KN/S = 259.67
memory per node = 4503 bytes
gc time  = 364.88%
total time = 21.3408372 seconds

### Implemented pinned tile algorithm

Perft(0) = 1
KN/S = 147.06
memory per node = 3360 bytes
gc time  = 0.0%
total time = 6.8e-6 seconds

Perft(1) = 7
KN/S = 11.84
memory per node = 5872 bytes
gc time  = 0.0%
total time = 0.0005912 seconds

Perft(2) = 294
KN/S = 237.81
memory per node = 4428 bytes
gc time  = 0.0%
total time = 0.0012363 seconds

Perft(3) = 6678
KN/S = 469.19
memory per node = 4677 bytes
gc time  = 0.0%
total time = 0.014233 seconds

Perft(4) = 151686
KN/S = 504.39
memory per node = 4695 bytes
gc time  = 0.0%
total time = 0.3007334 seconds

Perft(5) = 5487312
KN/S = 290.58
memory per node = 4558 bytes
gc time  = 753.14%
total time = 18.8842918 seconds

still counting too many moves at perft(5)

## Better allocation management, much faster, but perft 5 not working

Perft(1)         = 7
KN/S             = 574.0
memory per node  = 1952 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(2)         = 294
KN/S             = 6323.0
memory per node  = 185 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(3)         = 6.678
KN/S             = 1456.0
memory per node  = 438 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(4)         = 151.686
KN/S             = 2032.0
memory per node  = 457 bytes
gc time          = 1.0%
total time       = 0.1 seconds

Perft(5)         = 5.420.628
KN/S             = 2973.0
memory per node  = 320 bytes
gc time          = 12.0%
total time       = 1.8 seconds

5.420.628 vs 5,427,108
6.480 te weinig
ongeveer 0.11%

# Reduced allocations, better typing

Perft(1)         = 7
KN/S             = 361
memory per node  = 2.149 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(2)         = 294
KN/S             = 2.860
memory per node  = 168 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(3)         = 6.678
KN/S             = 3.184
memory per node  = 275 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(4)         = 151.686
KN/S             = 3.912
memory per node  = 286 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.420.628
KN/S             = 5.607
memory per node  = 217 bytes
gc time          = 8.0%
total time       = 1.0 seconds

Perft(6)         = 191.923.272
KN/S             = 4.924
memory per node  = 220 bytes
gc time          = 301.0%
total time       = 39.0 seconds

Lots of GC time! <- the problem is that the valid moves need to be stored, a single buffer does not work directly because in iterating over moves, new moves need to be created

## Allow pillbug special moves (also via mosquito) even when pillbug itself is pinned

Perft(4)         = 151.686
KN/S             = 3.612
memory per node  = 286 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 5.542
memory per node  = 218 bytes
gc time          = 8.0%
total time       = 1.0 seconds

Perft(6)         = 192.353.928
KN/S             = 5.262
memory per node  = 220 bytes
gc time          = 291.0%
total time       = 36.6 seconds

Perft 6 is still not working however. Counting 24 too many moves?!

## Fixing pillbug moves

Perft(4)         = 151.686
KN/S             = 3.665
memory per node  = 286 bytes
gc time          = 1.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 5.571
memory per node  = 219 bytes
gc time          = 7.0%
total time       = 1.0 seconds

Perft(6)         = 192.353.904
KN/S             = 5.248
memory per node  = 220 bytes
gc time          = 263.0%
total time       = 36.7 seconds

## Avoiding allocations without bump

Perft(4)         = 151.686
KN/S             = 3.242
memory per node  = 115 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 4.861
memory per node  = 107 bytes
gc time          = 5.0%
total time       = 1.1 seconds

Perft(6)         = 192.353.904
KN/S             = 6.378
memory per node  = 107 bytes
gc time          = 127.0%
total time       = 30.2 seconds

## Avoiding allocations with bump

Perft(4)         = 151.686
KN/S             = 3.612
memory per node  = 121 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 4.327
memory per node  = 106 bytes
gc time          = 5.0%
total time       = 1.3 seconds

Perft(6)         = 192.353.904
KN/S             = 4.493
memory per node  = 106 bytes
gc time          = 151.0%
total time       = 42.8 seconds

## Continue without
## Better move setting

Perft(4)         = 151.686
KN/S             = 7.880
memory per node  = 115 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 9.033
memory per node  = 107 bytes
gc time          = 3.0%
total time       = 0.6 seconds

Perft(6)         = 192.353.904
KN/S             = 9.437
memory per node  = 107 bytes
gc time          = 90.0%
total time       = 20.4 seconds

## Do not set moves in the valid moves array, but an index representing the move

Perft(1)         = 7
KN/S             = 405
memory per node  = 1.945 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(2)         = 294
KN/S             = 3.467
memory per node  = 98 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(3)         = 6.678
KN/S             = 14.791
memory per node  = 32 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(4)         = 151.686
KN/S             = 13.609
memory per node  = 29 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 15.561
memory per node  = 29 bytes
gc time          = 1.0%
total time       = 0.3 seconds

Perft(6)         = 192.353.904
KN/S             = 15.968
memory per node  = 29 bytes
gc time          = 28.0%
total time       = 12.0 seconds

## Use UInt32 for indexes to save some allocs

Perft(1)         = 7
KN/S             = 320
memory per node  = 1.938 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(2)         = 294
KN/S             = 5.904
memory per node  = 91 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(3)         = 6.678
KN/S             = 6.758
memory per node  = 24 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(4)         = 151.686
KN/S             = 8.267
memory per node  = 21 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 17.707
memory per node  = 21 bytes
gc time          = 0.0%
total time       = 0.3 seconds

Perft(6)         = 192.353.904
KN/S             = 17.313
memory per node  = 21 bytes
gc time          = 28.0%
total time       = 11.1 seconds

## Improved all neighs computation

Perft(4)         = 151.686
KN/S             = 19.264
memory per node  = 21 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 23.222
memory per node  = 21 bytes
gc time          = 1.0%
total time       = 0.2 seconds

Perft(6)         = 192.353.904
KN/S             = 22.002
memory per node  = 21 bytes
gc time          = 30.0%
total time       = 8.7 seconds

## Avoid allocataions by smarter loop in placement locs recalculation, save history as int with predefined vector, use MVector over SizedVector for valid action buffer

Perft(4)         = 151.686
KN/S             = 50.775
memory per node  = 11 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 49.040
memory per node  = 13 bytes
gc time          = 1.0%
total time       = 0.1 seconds

Perft(6)         = 192.353.904
KN/S             = 63.238
memory per node  = 14 bytes
gc time          = 10.0%
total time       = 3.0 seconds

## Avoid allocations by returning the board.last_history_index in depth 1 perft instead of the length of the actions

Perft(4)         = 151.686
KN/S             = 25.910
memory per node  = 1.15 bytes
gc time          = 0.0%
total time       = 0.01 seconds

Perft(5)         = 5.427.108
KN/S             = 87.688
memory per node  = 3.84 bytes
gc time          = 0.0%
total time       = 0.06 seconds

Perft(6)         = 192.353.904
KN/S             = 82.476
memory per node  = 3.93 bytes
gc time          = 6.0%
total time       = 2.33 seconds

## After fix for perft(7), lots of gc

Perft(7)         = 3.149.086.830
KN/S             = 27.632
memory per node  = 46.7 bytes
gc time          = 989.0%
total time       = 113.97 seconds

## lots of bumper noescape buffers

Perft(4)         = 151.686
KN/S             = 30.510
memory per node  = 0.19 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 93.038
memory per node  = 1.49 bytes
gc time          = 0.0%
total time       = 0.06 seconds

Perft(6)         = 192.353.904
KN/S             = 89.983
memory per node  = 1.55 bytes
gc time          = 4.0%
total time       = 2.14 seconds

## Remove a number of allocating filters and maps

Perft(4)         = 151.686
KN/S             = 23.818
memory per node  = 0.19 bytes
gc time          = 0.0%
total time       = 0.01 seconds

Perft(5)         = 5.427.108
KN/S             = 101.149
memory per node  = 0.14 bytes
gc time          = 0.0%
total time       = 0.05 seconds

Perft(6)         = 192.353.904
KN/S             = 96.571
memory per node  = 0.14 bytes
gc time          = 0.0%
total time       = 1.99 seconds

## Remove more filter and maps to reach no allocations in perft steps (move generation)
Perft(4)         = 151.686
KN/S             = 37.939
memory per node  = 0.08 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 98.246
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.06 seconds

Perft(6)         = 192.353.904
KN/S             = 101.357
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 1.9 seconds

## A bunch of optimization (type stability, avoidance of map, for each)
### Executed on less performant laptop

Perft(4)         = 151.686
KN/S             = 58.820
memory per node  = 0.08 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 180.346
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.03 seconds

Perft(6)         = 192.353.904
KN/S             = 195.967
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.98 seconds

## Use bit boards for generating placement locs

Perft(3)         = 6.678
KN/S             = 109.836
memory per node  = 1.92 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(4)         = 151.686
KN/S             = 166.725
memory per node  = 0.08 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 449.852
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.01 seconds

Perft(6)         = 192.353.904
KN/S             = 304.857
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.63 seconds

## Better usage of bit boards, small optimizations

Perft(4)         = 151.686
KN/S             = 381.415
memory per node  = 0.22 bytes
gc time          = 0.0%
total time       = 0.0 seconds

Perft(5)         = 5.427.108
KN/S             = 523.020
memory per node  = 0.01 bytes
gc time          = 0.0%
total time       = 0.01 seconds

Perft(6)         = 192.353.904
KN/S             = 315.837
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.61 seconds

### FIX / CHECK PILLBUG RULES
https://boardgamegeek.com/boardgame/139666/hive-the-pillbug


## Trying perft 7

Perft(5) 	 = 5.427.108
KN/S 		 = 241.079
memory per node  = 0.14 bytes
gc time 	 = 0.0%
total time 	 = 0.02 seconds

Perft(6) 	 = 192.353.904
KN/S 		 = 335.204
memory per node  = 0.0 bytes
gc time 	 = 0.0%
total time 	 = 0.57 seconds

Perft(7) 	 = 3.149.629.068
KN/S 		 = 118.606
memory per node  = 0.0 bytes
gc time 	 = 0.0%
total time 	 = 26.56 seconds

## Another try (more height in the ladybug calculation)

erft(5) 	 = 5.427.108
KN/S 		 = 529.843
memory per node  = 0.01 bytes
gc time 	 = 0.0%
total time 	 = 0.01 seconds

Perft(6) 	 = 192.353.904
KN/S 		 = 330.585
memory per node  = 0.0 bytes
gc time 	 = 0.0%
total time 	 = 0.58 seconds

Perft(7) 	 = 3.151.582.332
KN/S 		 = 112.800
memory per node  = 0.0 bytes
gc time 	 = 0.0%
total time 	 = 27.94 seconds


##  Failing perfts
others are good.
MPGame 7 deep fails, should be 1,363,837,116
There is a problem with pillbug mosquito interaction.
Even if the

## Spider duplicate fix, mosquito duplicate fix, game end with covered queen fix

Perft(5)         = 5.427.108
KN/S             = 299.608
memory per node  = 0.01 bytes
gc time          = 0.0%
total time       = 0.02 seconds

Perft(6)         = 192.353.904
KN/S             = 207.166
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.93 seconds

Perft(7)         = 3.151.035.948
KN/S             = 88.727
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 35.51 seconds

## Only do a general pinned updated once the pinned dict is needed, not immediately when it is detected that a simple update will not suffice

Perft(5)         = 5.427.108
KN/S             = 217.843
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.02 seconds

Perft(6)         = 192.353.904
KN/S             = 486.051
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.4 seconds

Perft(7)         = 3.151.035.948
KN/S             = 143.664
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 21.93 seconds


# Known solutions (MLPGame)

https://github.com/jonthysell/Mzinga/wiki/Perft

goal:
1:                  7
2:                294
3:              6,678
4:            151,686
5:          5,427,108
6:        192,353,904
7:      3,151,035,948
8:     50,945,151,390
9:  2,784,830,280,258

## the above results are sufficient. Further down in the search tree, the bot performs worse. From now on, perft results are shown from the following start state:
Base+MLP;InProgress;white[11];wB1;bS1 wB1-;wQ /wB1;bQ bS1/;wG1 -wB1;bG1 bS1-;wM -wQ;bM bQ-;wP /wQ;bP bQ/;wL -wG1;bL bG1-;wA1 wQ\;bB1 \bQ;wS1 wA1-;bA1 -bB1;wA2 -wP;bA2 bP-;wA2 wS1/;bA2 /bA1

As of right now the intsect results are:

Perft(3)         = 1.356.195
KN/S             = 21.846
memory per node  = 0.05 bytes
gc time          = 0.0%
total time       = 0.06 seconds

Perft(4)         = 151.460.537
KN/S             = 25.845
memory per node  = 0.14 bytes
gc time          = 0.0%
total time       = 5.86 seconds

### nokamute
at 5 deep nokamute finds 15.431.526.868 intsect first needs to speed up

speeds of nokamute at this level are ~90k KN/s at level 4

## Ran it again with a julia minor version bump after ~6 months of no work, faster somehow haha

Perft(3)         = 1.356.195
KN/S             = 52.711
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 0.03 seconds

Perft(4)         = 151.460.537
KN/S             = 49.559
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 3.06 seconds


## Did some tests with larger bit boards: See bigger_bb_benchmark.jl

Slow downs of 2-3x were observed with larger bit boards



## Lots of changes have been made: Use hex sets to avoid deduplication of generated moves, use cache for antmoves & pinned tiles

Base+MLP;InProgress;white[5];wL;bL wL\;wM \wL;bM bL\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-;wA2 wQ\;bA2 bA1\;wA2 /bA2;bA1 /wA1;wB1 wQ\;bP bA2-;wM wB1\;bB1 \bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1

(using a pre allocated cache, results are added by mutating old elements)

Perft(4)         = 52.745.320

Perft(5)         = 3.861.112.056
KN/S             = 111.160
memory per node  = 0.0 bytes
gc time          = 0.0%
total time       = 34.73 seconds

(using an empty cache, results are copies into it)

time performance is similar at top speed, but less reliable because of gc. Continuing with overwriting.



