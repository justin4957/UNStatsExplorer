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

"""
Find fuzzy matches using Jaro-Winkler distance
Returns vector of tuples: (code, description, similarity_score)
"""
function find_fuzzy_matches(
    input::String,
    valid_codes::Vector{String},
    descriptions::Vector{String};
    threshold::Float64=0.6,
    max_results::Int=5
)::Vector{Tuple{String, String, Float64}}
    matches = Tuple{String, String, Float64}[]
    input_lower = lowercase(input)

    for (code, desc) in zip(valid_codes, descriptions)
        # Check code similarity
        code_score = compare(input_lower, lowercase(code), JaroWinkler())

        # Check description similarity (weighted lower)
        desc_score = compare(input_lower, lowercase(desc), JaroWinkler()) * 0.7

        # Use the better score
        max_score = max(code_score, desc_score)

        if max_score >= threshold
            push!(matches, (code, desc, max_score))
        end
    end

    # Sort by score (descending) and take top N
    sort!(matches, by=x->x[3], rev=true)
    return matches[1:min(max_results, end)]
end

"""
Get validated code with fuzzy matching suggestions
Returns: (validated_code, was_corrected)
"""
function get_validated_code(
    prompt::String,
    valid_codes::Vector{String},
    descriptions::Vector{String};
    allow_empty::Bool=false,
    fuzzy_threshold::Float64=0.6
)::Union{Tuple{String, Bool}, Tuple{Nothing, Bool}}

    while true
        print(prompt)
        input = String(strip(readline()))

        # Handle empty input
        if isempty(input)
            if allow_empty
                return (nothing, false)
            else
                println("⚠️  Input cannot be empty. Please try again.")
                continue
            end
        end

        # Check for exact match (case-insensitive)
        exact_match_idx = findfirst(x -> lowercase(x) == lowercase(input), valid_codes)
        if !isnothing(exact_match_idx)
            code = valid_codes[exact_match_idx]
            println("✓ Selected: $(descriptions[exact_match_idx])")
            return (code, false)
        end

        # Try fuzzy matching
        suggestions = find_fuzzy_matches(input, valid_codes, descriptions, threshold=fuzzy_threshold)

        if !isempty(suggestions)
            println("\n💡 Did you mean:")
            for (i, (code, desc, score)) in enumerate(suggestions)
                score_pct = round(Int, score * 100)
                # Truncate description if too long
                short_desc = length(desc) > 60 ? desc[1:57] * "..." : desc
                println("  [$i] $code - $short_desc ($(score_pct)% match)")
            end
            println("  [r] Re-enter")
            println("  [l] List all available codes")

            print("\nYour choice: ")
            choice = String(strip(readline()))

            if choice == "r" || choice == ""
                continue
            elseif choice == "l"
                println("\n📋 Available codes:")
                for (i, (code, desc)) in enumerate(zip(valid_codes, descriptions))
                    if i <= 20
                        short_desc = length(desc) > 60 ? desc[1:57] * "..." : desc
                        println("  $code - $short_desc")
                    end
                end
                if length(valid_codes) > 20
                    println("  ... and $(length(valid_codes) - 20) more")
                end
                println()
                continue
            else
                # Try to parse as number
                idx = tryparse(Int, choice)
                if !isnothing(idx) && 1 <= idx <= length(suggestions)
                    selected_code = suggestions[idx][1]
                    selected_desc = suggestions[idx][2]
                    println("✓ Selected: $selected_desc")
                    return (selected_code, true)
                else
                    println("⚠️  Invalid choice. Please try again.")
                    continue
                end
            end
        else
            println("\n⚠️  No matches found for '$input'")
            println("\n💡 Tips:")
            println("  • Check spelling")
            println("  • Try a shorter search term")
            println("  • Use partial codes (e.g., '1.1' instead of '1.1.1')")
            println("  • Type 'list' to see available options")

            print("\nTry again? (y/n): ")
            retry = lowercase(strip(readline()))
            if retry != "y"
                return (nothing, false)
            end
        end
    end
end

"""
Get multiple validated codes with fuzzy matching
Returns vector of validated codes
"""
function get_multi_validated_codes(
    prompt::String,
    valid_codes::Vector{String},
    descriptions::Vector{String};
    fuzzy_threshold::Float64=0.7
)::Vector{String}

    println(prompt)
    println("(Enter comma-separated values)")
    input = String(strip(readline()))

    if isempty(input)
        return String[]
    end

    selected = String[]
    parts = parse_list_input(input)

    for part in parts
        # Check for exact match
        exact_idx = findfirst(x -> lowercase(x) == lowercase(part), valid_codes)

        if !isnothing(exact_idx)
            code = valid_codes[exact_idx]
            push!(selected, code)
            println("  ✓ Added: $code")
        else
            # Try fuzzy match (higher threshold for auto-correction)
            suggestions = find_fuzzy_matches(part, valid_codes, descriptions, threshold=fuzzy_threshold, max_results=1)

            if !isempty(suggestions) && suggestions[1][3] >= 0.85
                # Auto-correct with high confidence
                code = suggestions[1][1]
                push!(selected, code)
                println("  ~ Auto-corrected '$part' to '$code'")
            else
                println("  ⚠️  Skipping invalid code: '$part'")
            end
        end
    end

    return selected
end
