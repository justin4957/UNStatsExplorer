"""
Quick start script - run this to get started with UNStatsExplorer
"""

using Pkg

# Activate and install dependencies if needed
println("Activating UNStatsExplorer environment...")
Pkg.activate(".")

println("Installing dependencies (this may take a few minutes on first run)...")
Pkg.instantiate()

println("\nLoading UNStatsExplorer...")
using UNStatsExplorer

println("\n" * "="^70)
println("WELCOME TO UN STATS EXPLORER!")
println("="^70)

# Create client
println("\nInitializing API client...")
client = SDGClient()

println("\nFetching SDG goals...")
goals = get_goals(client)

println("\n✓ Successfully connected to UN Stats API!")
println("✓ Retrieved $(nrow(goals)) SDG goals")

println("\n" * "="^70)
println("Quick Examples:")
println("="^70)

println("\n1. View all goals:")
println("   goals = get_goals(client)")

println("\n2. Search for indicators:")
println("   results = search_indicators(client, \"poverty\")")

println("\n3. Get data for specific indicator:")
println("   data = get_indicator_data(client, indicator=\"1.1.1\", time_period=[2020])")

println("\n4. Export data:")
println("   export_to_csv(data, \"output.csv\")")

println("\n5. Launch interactive explorer:")
println("   interactive_explorer()")

println("\n" * "="^70)
println("Sample Query - Poverty Data for 2020")
println("="^70)

# Run a simple example query
println("\nFetching poverty data (Indicator 1.1.1) for 2020...")
sample_data = get_indicator_data(
    client,
    indicator="1.1.1",
    time_period=[2020]
)

if nrow(sample_data) > 0
    println("\n✓ Retrieved $(nrow(sample_data)) data points")
    println("\nSample data (first 5 rows):")
    display(first(sample_data, 5))

    println("\n\nExporting sample data...")
    export_to_csv(sample_data, "sample_poverty_data_2020.csv")
    println("✓ Exported to sample_poverty_data_2020.csv")
else
    println("\nNo data available for this query")
end

println("\n" * "="^70)
println("Ready to explore!")
println("="^70)
println("\nNext steps:")
println("  • Check out the examples/ directory for more usage patterns")
println("  • Read README.md for complete API documentation")
println("  • Run interactive_explorer() for menu-driven interface")
println("\nHappy exploring! 🌍")
println("="^70)
