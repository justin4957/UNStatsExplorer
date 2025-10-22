"""
Display utilities for the interactive explorer
Handles table formatting and presentation
"""

# Color definitions for consistent styling
const COLOR_SUCCESS = Crayon(foreground = :green, bold = true)
const COLOR_ERROR = Crayon(foreground = :red, bold = true)
const COLOR_WARNING = Crayon(foreground = :yellow, bold = true)
const COLOR_INFO = Crayon(foreground = :blue)
const COLOR_HEADER = Crayon(foreground = :cyan, bold = true)
const COLOR_HIGHLIGHT = Crayon(foreground = :magenta)
const COLOR_RESET = Crayon(reset = true)

"""
Print colored success message
"""
function print_success(msg::String)
    println(COLOR_SUCCESS, "✓ ", msg, COLOR_RESET)
end

"""
Print colored error message
"""
function print_error(msg::String)
    println(COLOR_ERROR, "✗ ", msg, COLOR_RESET)
end

"""
Print colored warning message
"""
function print_warning(msg::String)
    println(COLOR_WARNING, "⚠  ", msg, COLOR_RESET)
end

"""
Print colored info message
"""
function print_info(msg::String)
    println(COLOR_INFO, "ℹ  ", msg, COLOR_RESET)
end

"""
Print colored header
"""
function print_header(text::String)
    println(COLOR_HEADER, text, COLOR_RESET)
end

"""
Print colored highlight text
"""
function print_highlight(text::String)
    println(COLOR_HIGHLIGHT, text, COLOR_RESET)
end

"""
Print loading message for long-running operation
"""
function print_loading(msg::String)
    print(COLOR_INFO, "⏳ ", msg, "...", COLOR_RESET)
    flush(stdout)
end

"""
Clear loading message and print completion
"""
function print_loaded(msg::String="Done")
    print("\r\033[K")  # Clear line
    print_success(msg)
end

"""
Execute a function with loading indicator
"""
function with_loading(f::Function, loading_msg::String, success_msg::String="Done")
    print_loading(loading_msg)
    result = f()
    print_loaded(success_msg)
    return result
end

"""
Show summary statistics for DataFrame
"""
function show_data_summary(df::DataFrame)
    println("\n" * "="^70)
    print_header("📊 DATA SUMMARY")
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
Display DataFrame with smart pagination and navigation
Automatically triggers pagination for datasets with 15+ rows
"""
function display_table_smart(
    df::DataFrame;
    max_rows_per_page::Int=15,
    show_summary::Bool=true
)
    total_rows = nrow(df)

    # Show summary first
    if show_summary && total_rows > 0
        show_data_summary(df)
    end

    if total_rows == 0
        print_warning("No data to display")
        return nothing
    end

    # If dataset is small enough, show all at once
    if total_rows <= max_rows_per_page
        println()
        pretty_table(df,
            maximum_number_of_columns=10)
        return nothing
    end

    # Paginated display for large datasets
    current_page = 1
    total_pages = ceil(Int, total_rows / max_rows_per_page)

    while true
        println("\n" * "="^70)
        print_info("Page $current_page of $total_pages ($(total_rows) total rows)")
        println("="^70)

        start_idx = (current_page - 1) * max_rows_per_page + 1
        end_idx = min(current_page * max_rows_per_page, total_rows)

        pretty_table(df[start_idx:end_idx, :],
            maximum_number_of_columns=10)

        println()
        print_info("Navigation: ")
        print("[n]ext [p]revious [f]irst [l]ast [q]uit [e]xport")
        print("\n> ")
        flush(stdout)

        choice = lowercase(strip(readline()))

        if choice == "n" && current_page < total_pages
            current_page += 1
        elseif choice == "p" && current_page > 1
            current_page -= 1
        elseif choice == "f"
            current_page = 1
        elseif choice == "l"
            current_page = total_pages
        elseif choice == "q"
            break
        elseif choice == "e"
            return :export
        else
            if current_page >= total_pages && (choice == "n" || choice == "")
                break
            elseif current_page <= 1 && choice == "p"
                print_warning("Already at first page")
            elseif current_page >= total_pages && choice == "n"
                print_warning("Already at last page")
            else
                print_warning("Invalid choice. Use [n]ext, [p]revious, [f]irst, [l]ast, [q]uit, or [e]xport")
            end
        end
    end

    return nothing
end

"""
Display DataFrame with smart formatting and summary
"""
function display_table(df::DataFrame; max_rows::Int=20, show_summary::Bool=true)
    # Use smart pagination for large datasets (15+ rows)
    if nrow(df) >= 15
        result = display_table_smart(df, max_rows_per_page=max_rows, show_summary=show_summary)
        return result
    end

    # Show summary first
    if show_summary && nrow(df) > 0
        show_data_summary(df)
    end

    if nrow(df) == 0
        print_warning("No data to display")
        return
    end

    # Display small tables directly
    println()
    pretty_table(df,
        maximum_number_of_columns=10)
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
    print_header(text)
    println("="^70)
end
