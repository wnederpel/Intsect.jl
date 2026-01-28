using PackageCompiler

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

println("\n✓ Build complete!")
println("Executable location: intsect_exe\\bin\\intsect.exe")
println("\nRun with: .\\intsect_exe\\bin\\intsect.exe")
