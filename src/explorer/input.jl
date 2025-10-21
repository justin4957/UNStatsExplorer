"""
Input handling utilities for the interactive explorer
Handles user input parsing and validation
"""

"""
Parse comma-separated input into vector of strings
"""
function parse_list_input(input::String)::Vector{String}
    if isempty(strip(input))
        return String[]
    end
    return [strip(item) for item in split(input, ",")]
end

"""
Parse year range or comma-separated years
Examples: "2010-2020" or "2010,2015,2020"
"""
function parse_year_input(input::String)::Union{Vector{Int}, Nothing}
    input = strip(input)

    if isempty(input)
        return nothing
    end

    try
        if occursin("-", input)
            # Parse range
            parts = split(input, "-")
            start_year = parse(Int, strip(parts[1]))
            end_year = parse(Int, strip(parts[2]))
            return collect(start_year:end_year)
        else
            # Parse comma-separated list
            return [parse(Int, strip(y)) for y in split(input, ",")]
        end
    catch e
        @warn "Failed to parse year input: $input" exception=e
        return nothing
    end
end
