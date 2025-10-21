"""
Display utilities for the interactive explorer
Handles table formatting and presentation
"""

"""
Show summary statistics for DataFrame
"""
function show_data_summary(df::DataFrame)
    println("\n" * "="^70)
    println("📊 DATA SUMMARY")
    println("="^70)
    println("  Total rows: $(nrow(df))")
    println("  Total columns: $(ncol(df))")

    if ncol(df) > 0
        println("  Columns: $(join(names(df), ", "))")
    end

    # Show unique values for key columns
    for col in [:geoAreaName, :timePeriod, :indicator, :goal, :code, :title]
        if col in propertynames(df)
            unique_vals = unique(skipmissing(df[!, col]))
            unique_count = length(unique_vals)
            if unique_count <= 5
                println("  Unique $col: $(join(unique_vals, ", "))")
            else
                println("  Unique $col: $unique_count")
            end
        end
    end
    println("="^70)
end

"""
Display DataFrame with smart formatting and summary
"""
function display_table(df::DataFrame; max_rows::Int=20, show_summary::Bool=true)
    # Show summary first
    if show_summary && nrow(df) > 0
        show_data_summary(df)
    end

    if nrow(df) == 0
        println("\n⚠️  No data to display")
        return
    end

    # Display table
    if nrow(df) > max_rows
        println("\nShowing first $max_rows of $(nrow(df)) rows:")
        pretty_table(first(df, max_rows),
            maximum_number_of_columns=10,
            maximum_number_of_rows=max_rows)
        println("\n... $(nrow(df) - max_rows) more rows (use export to save all)")
    else
        println()
        pretty_table(df,
            maximum_number_of_columns=10)
    end
end

"""
Clear screen for better navigation
"""
function clear_screen()
    print("\033[2J\033[H")
end

"""
Show a separator line
"""
function show_separator(char::String="─", width::Int=70)
    println(char^width)
end

"""
Show a prominent header
"""
function show_header(text::String)
    println("\n" * "="^70)
    println(text)
    println("="^70)
end
