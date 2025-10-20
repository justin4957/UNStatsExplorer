"""
Advanced filtering and data manipulation examples
"""

using UNStatsExplorer
using DataFrames
using Statistics

# Initialize client
client = SDGClient()

println("="^70)
println("Advanced Example 1: Multi-Country Health Indicators")
println("="^70)

# Fetch maternal mortality data for multiple countries
countries_of_interest = ["USA", "GBR", "SWE", "NOR", "IND", "NGA", "BRA"]

maternal_mortality = get_indicator_data(
    client,
    indicator="3.1.1",  # Maternal mortality ratio
    geoareas=countries_of_interest,
    time_period=collect(2010:2020)
)

println("Retrieved $(nrow(maternal_mortality)) data points")

# Calculate summary statistics by country
if nrow(maternal_mortality) > 0
    # Convert value to numeric (handle any strings)
    maternal_mortality.value_numeric = tryparse.(Float64, string.(maternal_mortality.value))

    # Group by country and calculate statistics
    country_stats = combine(
        groupby(maternal_mortality, :geoAreaName),
        :value_numeric => mean => :mean_mortality,
        :value_numeric => std => :std_mortality,
        :timePeriod => minimum => :first_year,
        :timePeriod => maximum => :last_year,
        nrow => :data_points
    )

    println("\nSummary by country:")
    display(country_stats)

    # Export detailed data and summary
    export_multi_sheet_xlsx(
        Dict(
            "Raw Data" => maternal_mortality,
            "Country Summary" => country_stats
        ),
        "maternal_mortality_analysis.xlsx"
    )

    println("\nExported to maternal_mortality_analysis.xlsx")
end

println("\n" * "="^70)
println("Advanced Example 2: Time Series Analysis")
println("="^70)

# Get renewable energy data for a region
energy_data = get_indicator_data(
    client,
    indicator="7.2.1",  # Renewable energy share
    geoareas=["001"],   # World
    time_period=collect(2000:2023)
)

println("Retrieved $(nrow(energy_data)) data points for global renewable energy")

if nrow(energy_data) > 0
    # Sort by time period
    sort!(energy_data, :timePeriod)

    # Calculate year-over-year change
    if nrow(energy_data) > 1
        energy_data.value_numeric = tryparse.(Float64, string.(energy_data.value))

        # Calculate percentage change
        changes = Float64[]
        for i in 2:nrow(energy_data)
            if !ismissing(energy_data.value_numeric[i]) && !ismissing(energy_data.value_numeric[i-1])
                pct_change = ((energy_data.value_numeric[i] - energy_data.value_numeric[i-1]) /
                             energy_data.value_numeric[i-1]) * 100
                push!(changes, pct_change)
            else
                push!(changes, missing)
            end
        end

        # Add to dataframe (first row gets missing)
        energy_data.yoy_change = vcat([missing], changes)

        println("\nRecent trends in global renewable energy:")
        display(last(energy_data, 10))
    end

    export_to_csv(energy_data, "renewable_energy_trends.csv")
    println("\nExported to renewable_energy_trends.csv")
end

println("\n" * "="^70)
println("Advanced Example 3: Regional Comparison")
println("="^70)

# Compare poverty rates across regions
regions = ["002", "009", "019", "142", "150"]  # Africa, Oceania, Americas, Asia, Europe

poverty_by_region = get_indicator_data(
    client,
    indicator="1.1.1",
    geoareas=regions,
    time_period=[2015, 2020]  # Compare two time points
)

println("Retrieved $(nrow(poverty_by_region)) data points for regional poverty comparison")

if nrow(poverty_by_region) > 0
    # Pivot data for easier comparison
    poverty_by_region.value_numeric = tryparse.(Float64, string.(poverty_by_region.value))

    # Create comparison by region and year
    comparison = unstack(
        poverty_by_region[:, [:geoAreaName, :timePeriod, :value_numeric]],
        :timePeriod,
        :value_numeric
    )

    println("\nPoverty rates by region:")
    display(comparison)

    export_to_xlsx(comparison, "regional_poverty_comparison.xlsx")
    println("\nExported to regional_poverty_comparison.xlsx")
end

println("\n" * "="^70)
println("Advanced Example 4: Multiple Indicators for Single Country")
println("="^70)

# Get all Goal 3 (Health) indicators for a specific country
health_indicators_usa = get_indicator_data(
    client,
    goal="3",
    geoareas=["USA"],
    time_period=[2020]
)

println("Retrieved $(nrow(health_indicators_usa)) health indicators for USA in 2020")

if nrow(health_indicators_usa) > 0
    # Select key columns
    usa_health_summary = health_indicators_usa[:, [:indicator, :seriesDescription, :value, :units]]

    println("\nUSA Health Indicators (2020):")
    display(first(usa_health_summary, 15))

    export_to_csv(usa_health_summary, "usa_health_2020.csv")
    println("\nExported to usa_health_2020.csv")
end

println("\n" * "="^70)
println("Advanced examples completed!")
println("="^70)
