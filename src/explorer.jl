"""
Interactive CLI explorer for browsing SDG data
"""

using REPL

# Include explorer modules
include("explorer/display.jl")
include("explorer/input.jl")
include("explorer/menu.jl")

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
            countries = isempty(country_input) ? nothing : parse_list_input(country_input)

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
            areas = parse_list_input(areas_input)

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
