"""
Menu navigation and interaction logic for the interactive explorer
"""

"""
Interactive menu for exploring SDG goals
"""
function explore_goals(client::SDGClient)
    goals = get_goals(client)

    show_header("SDG GOALS ($(nrow(goals)) total)")
    display_table(goals, max_rows=17, show_summary=true)

    println("\n📌 NAVIGATION:")
    println("  • Enter a goal code (1-17) to explore indicators")
    println("  • Type 'back' or 'b' to return to main menu")
    println("  • Type 'export' or 'e' to save goals list")
    print("\nYour choice: ")

    choice = strip(readline())

    if choice in ["back", "b", ""]
        return
    elseif choice in ["export", "e"]
        export_data(goals, "sdg_goals.csv")
        println("✓ Exported to sdg_goals.csv")
        println("\nPress Enter to continue...")
        readline()
    elseif !isempty(choice)
        explore_goal_detail(client, choice)
    end
end

"""
Explore a specific goal in detail
"""
function explore_goal_detail(client::SDGClient, goal_code::String)
    show_header("GOAL $goal_code - INDICATORS")

    indicators = get_indicators(client, goal=goal_code)

    if nrow(indicators) == 0
        println("\n⚠️  No indicators found for goal $goal_code")
        println("\nPress Enter to return...")
        readline()
        return
    end

    display_table(indicators, max_rows=20, show_summary=true)

    println("\n📌 NAVIGATION:")
    println("  • Enter an indicator code (e.g., $(indicators.code[1])) to view data")
    println("  • Type 'search <keyword>' or 's <keyword>' to search indicators")
    println("  • Type 'export' or 'e' to save indicator list")
    println("  • Type 'back' or 'b' to return")
    print("\nYour choice: ")

    choice = strip(readline())

    if choice in ["back", "b", ""]
        return
    elseif choice in ["export", "e"]
        filename = "goal_$(goal_code)_indicators.csv"
        export_data(indicators, filename)
        println("✓ Exported to $filename")
        println("\nPress Enter to continue...")
        readline()
    elseif startswith(lowercase(choice), "search ") || startswith(lowercase(choice), "s ")
        # Extract keyword after "search " or "s "
        keyword = if startswith(lowercase(choice), "search ")
            String(strip(choice[8:end]))
        else
            String(strip(choice[3:end]))
        end
        println("\n🔍 Searching for: '$keyword'")
        results = search_indicators(client, keyword, goal=goal_code)
        display_table(results, show_summary=true)
        println("\nPress Enter to continue...")
        readline()
    else
        # Assume it's an indicator code
        indicator_code = String(strip(choice))
        explore_indicator_data(client, indicator_code)
    end
end

"""
Explore indicator data with filtering
"""
function explore_indicator_data(client::SDGClient, indicator_code::String)
    show_header("INDICATOR $indicator_code - DATA QUERY")

    println("\n📊 FETCH OPTIONS:")
    println("  • Type 'all' or 'a' for all available data (may be large)")
    println("  • Type 'filter' or 'f' to specify countries and years")
    println("  • Type 'back' or 'b' to return")
    print("\nYour choice: ")

    choice = strip(lowercase(readline()))

    if choice in ["back", "b", ""]
        return
    elseif choice in ["all", "a"]
        println("\n⏳ Fetching all data for indicator $indicator_code...")
        data = get_indicator_data(client, indicator=indicator_code)

        if nrow(data) > 0
            display_table(data, max_rows=50, show_summary=true)
            export_choice(data, "indicator_$(indicator_code)")
        else
            println("\n⚠️  No data available for this indicator")
            println("\nPress Enter to continue...")
            readline()
        end
    elseif choice in ["filter", "f"]
        filtered_query(client, indicator_code)
    else
        println("\n⚠️  Invalid choice. Please try again.")
        println("\nPress Enter to continue...")
        readline()
    end
end

"""
Build a filtered query interactively
"""
function filtered_query(client::SDGClient, indicator_code::String)
    show_header("FILTERED QUERY BUILDER")

    # Get countries
    println("\n🌍 COUNTRY SELECTION:")
    println("  Enter country codes separated by commas (e.g., USA, GBR, JPN)")
    println("  Or leave empty to include all countries")
    print("\nCountry codes: ")
    country_input = strip(readline())
    countries = if isempty(country_input)
        nothing
    else
        parse_list_input(country_input)
    end

    # Get years
    println("\n📅 TIME PERIOD SELECTION:")
    println("  Enter years as:")
    println("    • Range: 2010-2020")
    println("    • List: 2010, 2015, 2020")
    println("  Or leave empty to include all years")
    print("\nYears: ")
    year_input = strip(readline())
    years = parse_year_input(year_input)

    # Summary of query
    println("\n📋 QUERY SUMMARY:")
    println("  Indicator: $indicator_code")
    println("  Countries: $(isnothing(countries) ? "All" : join(countries, ", "))")
    println("  Years: $(isnothing(years) ? "All" : join(years, ", "))")

    print("\nProceed with query? (y/n): ")
    confirm = strip(lowercase(readline()))

    if confirm != "y"
        println("\n⚠️  Query cancelled")
        println("\nPress Enter to return...")
        readline()
        return
    end

    println("\n⏳ Fetching filtered data...")
    data = get_indicator_data(
        client,
        indicator=indicator_code,
        geoareas=countries,
        time_period=years
    )

    if nrow(data) > 0
        display_table(data, max_rows=50, show_summary=true)
        export_choice(data, "indicator_$(indicator_code)_filtered")
    else
        println("\n⚠️  No data found matching your criteria")
        println("\nTry:")
        println("  • Different country codes")
        println("  • Different time period")
        println("  • Removing filters to see all available data")
        println("\nPress Enter to return...")
        readline()
    end
end

"""
Prompt user to export data
"""
function export_choice(df::DataFrame, base_name::String)
    println("\n💾 EXPORT OPTIONS:")
    println("  • Type 'csv' or 'c' for CSV format")
    println("  • Type 'json' or 'j' for JSON format")
    println("  • Type 'arrow' or 'a' for Arrow format (efficient binary)")
    println("  • Type 'excel' or 'x' for Excel format")
    println("  • Type 'no' or 'n' to skip export")
    print("\nExport format (or skip): ")

    choice = strip(lowercase(readline()))

    format_map = Dict(
        "csv" => ".csv", "c" => ".csv",
        "json" => ".json", "j" => ".json",
        "arrow" => ".arrow", "a" => ".arrow",
        "excel" => ".xlsx", "x" => ".xlsx"
    )

    if haskey(format_map, choice)
        filename = "$(base_name)_$(Dates.format(now(), "yyyymmdd_HHMMSS"))$(format_map[choice])"
        export_data(df, filename)
        println("\n✓ Exported $(nrow(df)) rows to: $filename")
        println("\nPress Enter to continue...")
        readline()
    elseif choice in ["no", "n", ""]
        # Skip export
    else
        println("\n⚠️  Invalid format. Export skipped.")
        println("\nPress Enter to continue...")
        readline()
    end
end
