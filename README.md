# Intsect

Welcome to Intsect! 

This is a hobby project with the aim to create the best hive bot yet.

This README is to be expanded.

# TODO before public release

Be able to compile the the package. 
```
PS C:\intsect> julia --project -e "using JuliaC; JuliaC.main(ARGS)" -- --output-exe test --bundle build --trim=no ..\Intsect
```
seems to work but it's kinda weird that you have to do the ../Intsect thing and it write some output to Intsect.jl inside the repo?

TODO: 
1. Move to github (with renamed package)
2. Add batch script to compile (It's likely needed to remove the full build dir every time)
3. Let compilation run from github actions
4. check if executable is relocatable