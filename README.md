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
1. check if executable from github works
2. check if executable is relocatable on it's own
3. get arenant to run with executable and in (windows) ci 