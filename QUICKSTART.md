# Quick Start Guide

Get up and running with UNStatsExplorer in 5 minutes!

## Installation

1. **Navigate to the project directory:**
```bash
cd UNStatsExplorer
```

2. **Launch Julia and activate the environment:**
```bash
julia
```

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()  # Install all dependencies
```

3. **Load the package:**
```julia
using UNStatsExplorer
```

## Option 1: Interactive Explorer (Easiest)

Launch the interactive menu-driven interface:

```julia
interactive_explorer()
```

Or run the helper script:
```bash
julia run_explorer.jl
```

The explorer provides:
- Browse all SDG goals and indicators
- Search by keyword
- Build custom queries with prompts
- Export data in multiple formats
- No coding required!

## Option 2: Quick Start Script

Run the included quick start example:

```julia
include("examples/quick_start.jl")
```

This will:
- Set up the environment
- Connect to the API
- Run a sample query
- Export sample data

## Option 3: Write Your Own Script

### Basic Pattern

```julia
using UNStatsExplorer

# 1. Create client
client = SDGClient()

# 2. Explore what's available
goals = get_goals(client)
indicators = get_indicators(client, goal="1")

# 3. Fetch data
data = get_indicator_data(
    client,
    indicator="1.1.1",
    time_period=[2020]
)

# 4. Export
export_to_csv(data, "my_data.csv")
```

## Common Tasks

### Find Indicators by Topic

```julia
# Search for climate-related indicators
climate = search_indicators(client, "climate")

# Search for health indicators
health = search_indicators(client, "health", goal="3")
```

### Get Data for Specific Countries

```julia
data = get_indicator_data(
    client,
    indicator="3.1.1",  # Maternal mortality
    geoareas=["USA", "GBR", "JPN"],
    time_period=[2015, 2020]
)
```

### Export in Different Formats

```julia
# CSV (universal)
export_to_csv(data, "output.csv")

# Arrow (fastest, most efficient)
export_to_arrow(data, "output.arrow")

# Excel (great for reports)
export_to_xlsx(data, "output.xlsx")

# JSON (web-friendly)
export_to_json(data, "output.json")
```

### Create Multi-Sheet Excel Reports

```julia
goals = get_goals(client)
indicators = get_indicators(client, goal="13")
data = get_indicator_data(client, goal="13")

export_multi_sheet_xlsx(
    Dict(
        "Goals" => goals,
        "Indicators" => indicators,
        "Data" => data
    ),
    "climate_report.xlsx"
)
```

## Geographic Area Codes

Quick reference for common codes:

| Code | Area |
|------|------|
| 001 | World |
| 002 | Africa |
| 009 | Oceania |
| 019 | Americas |
| 142 | Asia |
| 150 | Europe |
| USA | United States |
| GBR | United Kingdom |
| CHN | China |
| JPN | Japan |
| IND | India |
| BRA | Brazil |
| DEU | Germany |

Get all codes:
```julia
areas = get_geoareas(client)
```

## Examples

Check out the `examples/` directory:

- `quick_start.jl` - Get started immediately
- `basic_usage.jl` - Simple queries and exports
- `advanced_filtering.jl` - Complex analysis and filtering
- `batch_processing.jl` - Process multiple goals/indicators

Run any example:
```julia
include("examples/basic_usage.jl")
```

## Performance Tips

1. **Use caching**: Metadata is cached automatically
2. **Filter early**: Specify countries and years in the query
3. **Use Arrow format**: Fastest for large datasets
4. **Be specific**: Query specific indicators rather than entire goals

## Troubleshooting

### "Package not found" errors
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### API timeouts
```julia
# Increase timeout in config
config = SDGConfig(timeout=60)  # 60 seconds
client = SDGClient(config)
```

### Rate limiting issues
```julia
# Slow down requests
config = SDGConfig(rate_limit_ms=1000)  # 1 second between requests
client = SDGClient(config)
```

## Next Steps

1. Read the full [README.md](README.md) for complete API documentation
2. Explore the [examples/](examples/) directory
3. Check the [UN Stats API documentation](https://unstats.un.org/sdgapi/swagger/)

## Getting Help

- Check function documentation: `?get_indicator_data`
- Read error messages carefully
- Ensure you have internet connectivity
- Verify area codes and indicator codes are correct

Happy exploring! 🌍📊
