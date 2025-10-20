"""
Display utilities for the interactive explorer
Handles table formatting and presentation
"""

"""
Display DataFrame with smart formatting
"""
function display_table(df::DataFrame; max_rows::Int=20)
    if nrow(df) > max_rows
        println("\nShowing first $max_rows of $(nrow(df)) rows:")
        pretty_table(first(df, max_rows),
            maximum_number_of_columns=10,
            maximum_number_of_rows=max_rows)
        println("\n... $(nrow(df) - max_rows) more rows")
    else
        pretty_table(df,
            maximum_number_of_columns=10)
    end
end
