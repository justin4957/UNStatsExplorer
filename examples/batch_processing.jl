"""
Batch processing examples for multiple goals/indicators
"""

using UNStatsExplorer
using Dates

# Initialize client
client = SDGClient()

println("="^70)
println("Batch Processing Example 1: Export All Goals Metadata")
println("="^70)

# Create output directory
output_dir = "sdg_exports"
if !isdir(output_dir)
    mkpath(output_dir)
    println("Created output directory: $output_dir")
end

# Export metadata for all goals
goals = get_goals(client)
targets = get_targets(client)
indicators = get_indicators(client)
series = get_series(client)
areas = get_geoareas(client)

# Create comprehensive metadata export
export_multi_sheet_xlsx(
    Dict(
        "Goals" => goals,
        "Targets" => targets,
        "Indicators" => indicators,
        "Series" => series,
        "Geographic Areas" => areas
    ),
    joinpath(output_dir, "sdg_metadata_complete.xlsx")
)

println("Exported complete metadata to $output_dir/sdg_metadata_complete.xlsx")

println("\n" * "="^70)
println("Batch Processing Example 2: Process Multiple Goals")
println("="^70)

# Process first 5 SDG goals
goals_to_process = ["1", "2", "3", "4", "5"]

for goal_code in goals_to_process
    println("\nProcessing Goal $goal_code...")

    # Get indicators for this goal
    goal_indicators = get_indicators(client, goal=goal_code)
    println("  Found $(nrow(goal_indicators)) indicators")

    # Get data for recent years
    goal_data = get_indicator_data(
        client,
        goal=goal_code,
        time_period=[2019, 2020, 2021, 2022]
    )

    println("  Retrieved $(nrow(goal_data)) data points")

    if nrow(goal_data) > 0
        # Export using auto-naming
        timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
        filename = "goal_$(goal_code)_data_$(timestamp).arrow"
        export_to_arrow(goal_data, joinpath(output_dir, filename))
        println("  Exported to $filename")
    end

    # Small delay between goals to be respectful to API
    sleep(1)
end

println("\n" * "="^70)
println("Batch Processing Example 3: Process Indicators by Keyword")
println("="^70)

# Find and process all water-related indicators
keywords = ["water", "sanitation", "hygiene"]

for keyword in keywords
    println("\nSearching for '$keyword' indicators...")

    results = search_indicators(client, keyword)
    println("  Found $(nrow(results)) indicators")

    if nrow(results) > 0
        # Export indicator list
        filename = "indicators_$(keyword).csv"
        export_to_csv(results, joinpath(output_dir, filename))
        println("  Exported indicator list to $filename")

        # Optionally fetch data for first few indicators
        # (commented out to avoid long processing times)
        # for i in 1:min(3, nrow(results))
        #     indicator_code = results[i, :code]
        #     println("  Fetching data for $indicator_code...")
        #     data = get_indicator_data(client, indicator=indicator_code, time_period=[2020])
        #     if nrow(data) > 0
        #         export_to_arrow(data, joinpath(output_dir, "$(indicator_code)_data.arrow"))
        #     end
        # end
    end
end

println("\n" * "="^70)
println("Batch Processing Example 4: Multi-Country Reports")
println("="^70)

# Create reports for multiple countries
countries = ["USA", "CHN", "IND", "BRA", "DEU"]
selected_indicators = ["1.1.1", "3.1.1", "4.1.1", "7.2.1"]  # Poverty, Health, Education, Energy

for country in countries
    println("\nGenerating report for $country...")

    country_data = Dict{String, DataFrame}()

    for indicator in selected_indicators
        data = get_indicator_data(
            client,
            indicator=indicator,
            geoareas=[country],
            time_period=collect(2015:2023)
        )

        if nrow(data) > 0
            country_data["Indicator_$indicator"] = data
            println("  Added data for indicator $indicator ($(nrow(data)) rows)")
        end
    end

    if !isempty(country_data)
        filename = "$(country)_sdg_report.xlsx"
        export_multi_sheet_xlsx(country_data, joinpath(output_dir, filename))
        println("  Report saved to $filename")
    else
        println("  No data available for $country")
    end

    sleep(0.5)  # Brief delay between countries
end

println("\n" * "="^70)
println("Batch Processing Example 5: Time Series Export")
println("="^70)

# Export comprehensive time series for key global indicators
global_indicators = [
    "1.1.1",   # Poverty
    "2.1.1",   # Undernourishment
    "3.1.1",   # Maternal mortality
    "6.1.1",   # Water access
    "7.2.1",   # Renewable energy
    "13.1.1"   # Climate adaptation
]

global_time_series = Dict{String, DataFrame}()

for indicator in global_indicators
    println("\nFetching global data for indicator $indicator...")

    data = get_indicator_data(
        client,
        indicator=indicator,
        geoareas=["001"],  # World
        time_period=collect(2000:2023)
    )

    if nrow(data) > 0
        global_time_series["Indicator_$indicator"] = data
        println("  Retrieved $(nrow(data)) data points")
    end

    sleep(0.5)
end

if !isempty(global_time_series)
    export_multi_sheet_xlsx(
        global_time_series,
        joinpath(output_dir, "global_indicators_timeseries.xlsx")
    )
    println("\nGlobal time series exported to global_indicators_timeseries.xlsx")
end

println("\n" * "="^70)
println("All batch processing completed!")
println("Output directory: $output_dir")
println("="^70)

# List all files created
println("\nFiles created:")
for file in readdir(output_dir)
    filepath = joinpath(output_dir, file)
    size_mb = stat(filepath).size / (1024 * 1024)
    println("  - $file ($(round(size_mb, digits=2)) MB)")
end
