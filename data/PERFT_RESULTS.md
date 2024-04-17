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

## Make parallel, but also add history back into the struct, this seems to add a lot of allocations

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



https://github.com/jonthysell/Mzinga/wiki/Perft