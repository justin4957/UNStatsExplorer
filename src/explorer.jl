"""
Interactive CLI explorer for browsing SDG data
"""

using REPL

"""
Display DataFrame with pretty formatting
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

"""
Interactive menu for exploring SDG goals
"""
function explore_goals(client::SDGClient)
    goals = get_goals(client)

    println("\n" * "="^70)
    println("SDG GOALS ($(nrow(goals)) total)")
    println("="^70)

    display_table(goals)

    println("\nEnter goal code to explore (or 'back' to return): ")
    goal_code = readline()

    if goal_code != "back" && !isempty(goal_code)
        explore_goal_detail(client, goal_code)
    end
end

"""
Explore a specific goal in detail
"""
function explore_goal_detail(client::SDGClient, goal_code::String)
    println("\n" * "="^70)
    println("GOAL $goal_code - INDICATORS")
    println("="^70)

    indicators = get_indicators(client, goal=goal_code)

    if nrow(indicators) == 0
        println("No indicators found for goal $goal_code")
        return
    end

    display_table(indicators)

    println("\nOptions:")
    println("  [i] <code> - View indicator data")
    println("  [s] <keyword> - Search indicators")
    println("  [e] - Export indicator list")
    println("  [b] - Back")
    println("\nChoice: ")

    choice = readline()

    if startswith(choice, "i ")
        indicator_code = strip(split(choice, " ", limit=2)[2])
        explore_indicator_data(client, indicator_code)
    elseif startswith(choice, "s ")
        keyword = strip(split(choice, " ", limit=2)[2])
        results = search_indicators(client, keyword, goal=goal_code)
        display_table(results)
    elseif choice == "e"
        export_data(indicators, "goal_$(goal_code)_indicators.csv")
        println("Exported to goal_$(goal_code)_indicators.csv")
    end
end

"""
Explore indicator data with filtering
"""
function explore_indicator_data(client::SDGClient, indicator_code::String)
    println("\n" * "="^70)
    println("INDICATOR $indicator_code - DATA QUERY")
    println("="^70)

    println("\nFetch data options:")
    println("  [a] - All available data (may be large)")
    println("  [f] - Filtered query (specify countries and years)")
    println("  [b] - Back")
    println("\nChoice: ")

    choice = readline()

    if choice == "a"
        println("\nFetching all data for $indicator_code...")
        data = get_indicator_data(client, indicator=indicator_code)
        display_table(data, max_rows=50)

        if nrow(data) > 0
            export_choice(data, "indicator_$(indicator_code)")
        end
    elseif choice == "f"
        filtered_query(client, indicator_code)
    end
end

"""
Build a filtered query interactively
"""
function filtered_query(client::SDGClient, indicator_code::String)
    println("\n--- Filtered Query Builder ---")

    # Get countries
    println("\nEnter country codes (comma-separated, or leave empty for all): ")
    country_input = readline()
    countries = if isempty(country_input)
        nothing
    else
        [strip(c) for c in split(country_input, ",")]
    end

    # Get years
    println("\nEnter years (comma-separated or range like 2010-2020, or leave empty for all): ")
    year_input = readline()
    years = if isempty(year_input)
        nothing
    else
        if occursin("-", year_input)
            range_parts = split(year_input, "-")
            start_year = parse(Int, strip(range_parts[1]))
            end_year = parse(Int, strip(range_parts[2]))
            collect(start_year:end_year)
        else
            [parse(Int, strip(y)) for y in split(year_input, ",")]
        end
    end

    println("\nFetching filtered data...")
    data = get_indicator_data(
        client,
        indicator=indicator_code,
        geoareas=countries,
        time_period=years
    )

    display_table(data, max_rows=50)

    if nrow(data) > 0
        export_choice(data, "indicator_$(indicator_code)_filtered")
    end
end

"""
Prompt user to export data
"""
function export_choice(df::DataFrame, base_name::String)
    println("\nExport this data?")
    println("  [c] - CSV")
    println("  [j] - JSON")
    println("  [a] - Arrow")
    println("  [x] - Excel")
    println("  [n] - No")
    println("\nChoice: ")

    choice = readline()

    format_map = Dict(
        "c" => ".csv",
        "j" => ".json",
        "a" => ".arrow",
        "x" => ".xlsx"
    )

    if haskey(format_map, choice)
        filename = "$(base_name)_$(Dates.format(now(), "yyyymmdd_HHMMSS"))$(format_map[choice])"
        export_data(df, filename)
        println("\nExported to: $filename")
    end
end

"""
Main interactive explorer entry point
"""
function interactive_explorer()
    println("\n" * "="^70)
    println("UN STATS SDG DATA EXPLORER")
    println("="^70)
    println("\nInitializing client...")

    client = SDGClient()

    while true
        println("\n" * "-"^70)
        println("MAIN MENU")
        println("-"^70)
        println("  [g] - Browse Goals")
        println("  [i] - Search Indicators")
        println("  [s] - Query Series Data")
        println("  [a] - List Geographic Areas")
        println("  [c] - Compare Trends")
        println("  [q] - Quit")
        println("\nChoice: ")

        choice = readline()

        if choice == "g"
            explore_goals(client)
        elseif choice == "i"
            println("\nEnter search keyword: ")
            keyword = readline()
            results = search_indicators(client, keyword)
            display_table(results)
        elseif choice == "s"
            println("\nEnter series code: ")
            series_code = readline()

            println("\nEnter country codes (comma-separated, or leave empty): ")
            country_input = readline()
            countries = isempty(country_input) ? nothing : [strip(c) for c in split(country_input, ",")]

            data = get_series_data(client, series=series_code, geoareas=countries)
            display_table(data, max_rows=50)

            if nrow(data) > 0
                export_choice(data, "series_$(series_code)")
            end
        elseif choice == "a"
            areas = get_geoareas(client)
            display_table(areas, max_rows=50)

            println("\nExport geographic areas? (y/n): ")
            if readline() == "y"
                export_data(areas, "geoareas.csv")
                println("Exported to geoareas.csv")
            end
        elseif choice == "c"
            println("\nEnter series code: ")
            series_code = readline()

            println("\nEnter years (comma-separated): ")
            years_input = readline()
            years = [parse(Int, strip(y)) for y in split(years_input, ",")]

            println("\nEnter area codes (comma-separated, e.g., 001 for World): ")
            areas_input = readline()
            areas = [strip(a) for a in split(areas_input, ",")]

            data = compare_trends(client, series_code=series_code, years=years, area_codes=areas)
            display_table(data, max_rows=50)

            if nrow(data) > 0
                export_choice(data, "trends_$(series_code)")
            end
        elseif choice == "q"
            println("\nGoodbye!")
            break
        else
            println("\nInvalid choice. Please try again.")
        end
    end
end
