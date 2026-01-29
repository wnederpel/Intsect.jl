using PackageCompiler


# Prompt user for a name
print("Enter a name for this executable build: ")
user_name = readline()
user_name = strip(user_name)

# Replace spaces with dashes
folder_name = "intsect-" * replace(user_name, " " => "-")

# Write temporary precompile script
precompile_file = joinpath(@__DIR__, "..", "precompile_temp.jl")
open(precompile_file, "w") do io
    write(
        io,
        """
using Intsect

# Load complex mid-game position
game_string = raw"Base+MLP;InProgress;white[5];wL;bL wL\\;wM \\wL;bM bL\\;wA1 /wM;bA1 /bL;wQ wM/;bQ bM-;wA2 wQ\\;bA2 bA1\\;wA2 /bA2;bA1 /wA1;wB1 wQ\\;bP bA2-;wM wB1\\;bB1 \\bA2;wA3 -wQ;bS1 /bA1;wA3 -bS1"
board = from_game_string(game_string)

perft(4, board)

get_best_move(board, 4, -1; debug=false)

println("Precompilation complete")
""",
    )
end

# Create the executable
println("Building Intsect executable with Alder Lake optimizations...")
println("This may take several minutes...")

project_dir = joinpath(@__DIR__, "..")
output_dir = joinpath(project_dir, "intsect_exe")

create_app(
    project_dir,  # Source directory
    output_dir;   # Output directory
    precompile_execution_file=precompile_file,
    executables=["intsect" => "julia_main"],
    force=true,
    cpu_target="alderlake",  # Optimize for Alder Lake
    filter_stdlibs=true,  # Include only necessary standard libraries
    include_lazy_artifacts=false,  # Reduce size
)

# Clean up temporary file
rm(precompile_file; force=true)

# Copy to engines directory
project_dir_ref = joinpath(@__DIR__, "..")
engines_dir = joinpath(project_dir_ref, "engines")
target_dir = joinpath(engines_dir, folder_name)

println("\nCopying build to: $target_dir")
if isdir(target_dir)
    println("Warning: Directory already exists. Removing old version...")
    rm(target_dir; recursive=true, force=true)
end

cp(output_dir, target_dir; force=true)

# Create batch file launcher
bat_file = joinpath(engines_dir, folder_name * ".bat")
open(bat_file, "w") do io
    write(
        io,
        """
@echo off
cd /d "%~dp0$folder_name\\bin"
intsect.exe %*
""",
    )
end

println("✓ Build complete!")
println("Executable location: intsect_exe\\bin\\intsect.exe")
println("Engine directory: engines\\$folder_name")
println("Launcher script: engines\\$folder_name.bat")
println("\nRun with: .\\engines\\$folder_name.bat")
