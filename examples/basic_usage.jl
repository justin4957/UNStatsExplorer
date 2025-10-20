"""
Basic usage examples for UNStatsExplorer
"""

using UNStatsExplorer

# Initialize client with default configuration
client = SDGClient()

println("="^70)
println("Example 1: Fetching SDG Goals")
println("="^70)

goals = get_goals(client)
println("Retrieved $(nrow(goals)) SDG goals")
println("\nFirst 5 goals:")
display(first(goals, 5))

println("\n" * "="^70)
println("Example 2: Searching for Climate-Related Indicators")
println("="^70)

climate_indicators = search_indicators(client, "climate")
println("Found $(nrow(climate_indicators)) climate-related indicators")
display(first(climate_indicators, 5))

println("\n" * "="^70)
println("Example 3: Fetching Data for Specific Indicator")
println("="^70)

# Indicator 1.1.1: Proportion of population below international poverty line
data = get_indicator_data(
    client,
    indicator="1.1.1",
    geoareas=["USA", "GBR", "DEU"],  # USA, UK, Germany
    time_period=[2015, 2016, 2017, 2018, 2019, 2020]
)

println("Retrieved $(nrow(data)) data points")
display(first(data, 10))

println("\n" * "="^70)
println("Example 4: Exporting Data")
println("="^70)

# Export to different formats
if nrow(data) > 0
    export_to_csv(data, "poverty_data.csv")
    export_to_json(data, "poverty_data.json")
    export_to_arrow(data, "poverty_data.arrow")

    println("\nData exported to:")
    println("  - poverty_data.csv")
    println("  - poverty_data.json")
    println("  - poverty_data.arrow")
end

println("\n" * "="^70)
println("Example 5: Getting Geographic Areas")
println("="^70)

areas = get_geoareas(client)
println("Retrieved $(nrow(areas)) geographic areas")

# Filter to show only countries (not regions)
countries = filter(row -> row.geoAreaType == "Country", areas)
println("\nNumber of countries: $(nrow(countries))")
display(first(countries, 10))

println("\n" * "="^70)
println("Examples completed!")
println("="^70)
