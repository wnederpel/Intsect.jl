# Intsect

Welcome to Intsect! 

This is a hobby project with the aim to create the best hive bot yet.

This README is to be expanded.

## Build

build with JuliaC:
```
julia --project -e "using JuliaC; JuliaC.main(ARGS)" -- --output-exe intsect --bundle build --trim=no ..\Intsect.jl 
```

# TODO before public release

Be able to compile the the package. 
```
seems to work but it's kinda weird that you have to do the ../Intsect thing and it write some output to Intsect.jl inside the repo?

TODO: 
1. check if executable from github works
2. check if executable is relocatable on it's own
3. get arenant to run with executable and in (windows) ci 