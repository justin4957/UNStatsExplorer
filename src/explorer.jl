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
            # Get and validate series code
            print_loading("Loading series list"); series_list = get_series(client); print_loaded("Loaded $(nrow(series_list)) series")
            result = get_validated_code(
                "\nEnter series code: ",
                series_list.code,
                series_list.description,
                allow_empty=true,
                fuzzy_threshold=0.6
            )

            if isnothing(result[1])
                continue
            end
            series_code = result[1]

            # Get and validate country codes
            println("\nEnter country codes (comma-separated, or leave empty): ")
            country_input = strip(readline())

            countries = if isempty(country_input)
                nothing
            else
                print_loading("Loading geographic areas")
                geoareas = get_geoareas(client)
                print_loaded("Loaded $(nrow(geoareas)) geographic areas")

                println("\n⏳ Validating countries...")
                validated_countries = validate_multi_codes(
                    country_input,
                    geoareas.geoAreaCode,
                    geoareas.geoAreaName,
                    fuzzy_threshold=0.7
                )
                println()
                isempty(validated_countries) ? nothing : validated_countries
            end

            print_loading("Fetching series data")
            data = get_series_data(client, series=series_code, geoareas=countries)
            print_loaded("Fetched $(nrow(data)) data points")

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
            # Get and validate series code
            print_loading("Loading series list"); series_list = get_series(client); print_loaded("Loaded $(nrow(series_list)) series")
            result = get_validated_code(
                "\nEnter series code: ",
                series_list.code,
                series_list.description,
                allow_empty=true,
                fuzzy_threshold=0.6
            )

            if isnothing(result[1])
                continue
            end
            series_code = result[1]

            # Get years with improved parsing
            println("\nEnter years (comma-separated or range like 2010-2020): ")
            years_input = strip(readline())
            years = parse_year_input(years_input)

            if isnothing(years)
                print_warning("Invalid year format. Skipping trend comparison.")
                continue
            end

            # Get and validate area codes
            println("\nEnter area codes (comma-separated, e.g., 001 for World): ")
            areas_input = strip(readline())

            print_loading("Loading geographic areas")
            geoareas = get_geoareas(client)
            print_loaded("Loaded $(nrow(geoareas)) geographic areas")

            areas = if isempty(areas_input)
                String[]
            else
                println("\n⏳ Validating areas...")
                validated_areas = validate_multi_codes(
                    areas_input,
                    geoareas.geoAreaCode,
                    geoareas.geoAreaName,
                    fuzzy_threshold=0.7
                )
                println()
                validated_areas
            end

            if isempty(areas)
                print_warning("No valid areas specified. Skipping trend comparison.")
                continue
            end

            print_loading("Comparing trends")
            data = compare_trends(client, series_code=series_code, years=years, area_codes=areas)
            print_loaded("Fetched $(nrow(data)) data points")

            display_table(data, max_rows=50)

            if nrow(data) > 0
                export_choice(data, "trends_$(series_code)")
            end
        elseif choice == "q"
            print_info("Goodbye!")
            break
        else
            print_error("Invalid choice. Please try again.")
        end
    end
end
