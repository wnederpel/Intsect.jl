try
    # Your code that might raise an UndefVarError
    println(x)  # Assuming x is not defined
catch e
    if isa(e, UndefVarError)
        # Handle the UndefVarError silently or log it
        println("An undefined variable was accessed, but don't worry, we handled it.")
        io = IOBuffer()
        # Write the error message to the IOBuffer
        showerror(io, e)
        println("An error occurred: ", String(take!(io)))

        # Capture the full stack trace
        full_backtrace = catch_backtrace()
        # Select only the first 5 elements, if there are that many
        short_backtrace = full_backtrace[begin:(begin + 20)]

        # Reset the IOBuffer to reuse it for the backtrace
        seekstart(io)
        truncate(io, 0)

        # Write the shortened stack trace to the IOBuffer
        Base.show_backtrace(io, short_backtrace)
        # Print the formatted short stack trace
        println(String(take!(io)))
    else
        # Re-throw the error if it's not an UndefVarError
        rethrow(e)
    end
end

println("ok")
