# UNStatsExplorer.jl

![](https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExYnVxbnNpNDN4NDlsajF2ajg2cHFwb2NwbHkxeXI4ZG81NHZ6MWR6diZlcD12MV9naWZzX3NlYXJjaCZjdD1n/9ADoZQgs0tyww/giphy.gif)

A Julia package for exploring and exporting UN Stats SDG (Sustainable Development Goals) data with minimal overhead and maximum flexibility.

## Features

- **Simple API Client**: Rate-limited, retry-enabled HTTP client with automatic pagination
- **Comprehensive Metadata**: Access to goals, targets, indicators, series, and geographic areas
- **Flexible Querying**: Filter by indicators, countries, time periods, and more
- **Smart Caching**: Automatic caching of metadata to reduce API calls
- **Multiple Export Formats**: CSV, JSON, Arrow, and Excel support
- **Interactive Explorer**: CLI interface for browsing and querying data
- **Progress Tracking**: Built-in progress bars for large data fetches
- **Type-Safe**: Robust handling of missing data and type conversions

## Installation

```julia
using Pkg
Pkg.activate("path/to/UNStatsExplorer")
Pkg.instantiate()
```

## Quick Start

### Basic Usage

First, make sure to activate the package environment and load the package:

```julia
using Pkg
Pkg.activate("path/to/UNStatsExplorer")  # Use "." if already in the directory
using UNStatsExplorer

# Create client
client = SDGClient()

# Get all SDG goals
goals = get_goals(client)

# Get indicators for a specific goal
indicators = get_indicators(client, goal="1")

# Search for specific indicators
poverty_indicators = search_indicators(client, "poverty")

# Get data for a specific indicator
data = get_indicator_data(
    client,
    indicator="1.1.1",
    geoareas=["USA", "GBR", "JPN"],
    time_period=[2015, 2016, 2017, 2018, 2019, 2020]
)

# Export to CSV
export_to_csv(data, "poverty_data.csv")

# Or use smart export based on extension
export_data(data, "poverty_data.xlsx")
```

### Interactive Explorer

Launch the interactive CLI explorer:

```julia
using Pkg
Pkg.activate("path/to/UNStatsExplorer")  # Use "." if already in the directory
using UNStatsExplorer

interactive_explorer()
```

The explorer provides an intuitive menu-driven interface for:
- Browsing SDG goals and indicators
- Searching by keyword
- Building filtered queries
- Exporting data in multiple formats

## API Reference

### Client Configuration

```julia
# Create client with custom configuration
config = SDGConfig(
    base_url="https://unstats.un.org/sdgapi",
    timeout=30,              # Request timeout in seconds
    rate_limit_ms=500,       # Minimum milliseconds between requests
    max_retries=3,           # Number of retry attempts
    page_size=1000           # Records per page (max 1000)
)

client = SDGClient(config)
```

### Metadata Functions

#### `get_goals(client; force_refresh=false)`
Retrieve all SDG goals (cached by default).

**Returns**: DataFrame with columns: `code`, `title`, `description`

```julia
goals = get_goals(client)
```

#### `get_targets(client; goal=nothing, force_refresh=false)`
Retrieve SDG targets, optionally filtered by goal.

**Returns**: DataFrame with columns: `code`, `goal`, `title`, `description`

```julia
# All targets
targets = get_targets(client)

# Targets for goal 1
goal1_targets = get_targets(client, goal="1")
```

#### `get_indicators(client; goal=nothing, force_refresh=false)`
Retrieve SDG indicators, optionally filtered by goal.

**Returns**: DataFrame with columns: `code`, `goal`, `target`, `description`

```julia
indicators = get_indicators(client, goal="3")
```

#### `get_series(client; indicator=nothing, force_refresh=false)`
Retrieve data series, optionally filtered by indicator.

**Returns**: DataFrame with columns: `code`, `description`, `indicator`, `goal`, `target`

```julia
series = get_series(client, indicator="1.1.1")
```

#### `get_geoareas(client; force_refresh=false)`
Retrieve all geographic areas (countries, regions, etc.).

**Returns**: DataFrame with columns: `geoAreaCode`, `geoAreaName`, `geoAreaType`

```julia
areas = get_geoareas(client)
```

#### `search_indicators(client, keyword; goal=nothing)`
Search indicators by keyword in description.

```julia
health_indicators = search_indicators(client, "health")
```

### Data Retrieval Functions

#### `get_indicator_data(client; kwargs...)`
Fetch indicator data with flexible filtering.

**Parameters**:
- `indicator::String` - Indicator code (e.g., "1.1.1")
- `goal::String` - Goal code (e.g., "1")
- `geoareas::Vector{String}` - Geographic area codes
- `time_period::Vector{Int}` - Years to fetch
- `series::String` - Series code

**Returns**: DataFrame with columns: `goal`, `target`, `indicator`, `series`, `seriesDescription`, `geoAreaCode`, `geoAreaName`, `timePeriod`, `value`, `units`, `nature`, `source`

```julia
# Get data for specific indicator and countries
data = get_indicator_data(
    client,
    indicator="3.1.1",
    geoareas=["001", "002"],  # World and Africa
    time_period=[2015, 2020]
)

# Get all data for a goal
goal_data = get_indicator_data(client, goal="7")
```

#### `get_series_data(client; series, geoareas=nothing, time_period=nothing)`
Fetch data for a specific series.

```julia
data = get_series_data(
    client,
    series="SI_POV_DAY1",
    geoareas=["USA", "CHN"],
    time_period=[2010, 2015, 2020]
)
```

#### `compare_trends(client; series_code, years=[], area_codes=["001"], dimensions=[])`
Compare trends across different geographical levels with disaggregation.

```julia
trends = compare_trends(
    client,
    series_code="SH_STA_BRTC",
    years=[2015, 2020],
    area_codes=["001", "002", "150"]  # World, Africa, Europe
)
```

### Export Functions

#### `export_to_csv(df, filepath)`
Export DataFrame to CSV format.

```julia
export_to_csv(data, "sdg_data.csv")
```

#### `export_to_json(df, filepath; pretty=false)`
Export DataFrame to JSON format.

```julia
export_to_json(data, "sdg_data.json", pretty=true)
```

#### `export_to_arrow(df, filepath)`
Export DataFrame to Apache Arrow format (efficient binary).

```julia
export_to_arrow(data, "sdg_data.arrow")
```

#### `export_to_xlsx(df, filepath; sheet_name="Data")`
Export DataFrame to Excel format.

```julia
export_to_xlsx(data, "sdg_data.xlsx", sheet_name="SDG Data")
```

#### `export_data(df, filepath; kwargs...)`
Smart export based on file extension.

```julia
export_data(data, "output.csv")    # Automatically uses CSV
export_data(data, "output.arrow")  # Automatically uses Arrow
```

#### `auto_export(df, base_name; format=:csv, output_dir="./output")`
Export with auto-generated filename and timestamp.

```julia
auto_export(data, "poverty_indicators", format=:xlsx, output_dir="./data")
# Creates: ./data/poverty_indicators_20250120_143022.xlsx
```

#### `export_multi_sheet_xlsx(data_dict, filepath)`
Export multiple DataFrames to Excel with separate sheets.

```julia
export_multi_sheet_xlsx(
    Dict(
        "Goals" => goals,
        "Indicators" => indicators,
        "Data" => data
    ),
    "sdg_report.xlsx"
)
```

## Common Use Cases

### 1. Export All Poverty Indicators

```julia
using UNStatsExplorer

client = SDGClient()

# Search for poverty-related indicators
poverty = search_indicators(client, "poverty")

# Get data for all poverty indicators
data = get_indicator_data(client, goal="1")

# Export to multiple formats
export_data(data, "poverty_data.csv")
export_data(data, "poverty_data.arrow")
```

### 2. Compare Countries Over Time

```julia
# Get maternal mortality data for specific countries
data = get_indicator_data(
    client,
    indicator="3.1.1",
    geoareas=["USA", "GBR", "SWE", "JPN"],
    time_period=collect(2000:2020)
)

# Export for analysis in other tools
export_to_arrow(data, "maternal_mortality_comparison.arrow")
```

### 3. Build Custom Reports

```julia
# Gather multiple datasets
goals = get_goals(client)
indicators = get_indicators(client, goal="13")
climate_data = get_indicator_data(client, goal="13")
areas = get_geoareas(client)

# Export as multi-sheet Excel report
export_multi_sheet_xlsx(
    Dict(
        "Goals" => goals,
        "Indicators" => indicators,
        "Climate Data" => climate_data,
        "Geographic Areas" => areas
    ),
    "climate_action_report.xlsx"
)
```

### 4. Batch Processing

```julia
# Process multiple goals
for goal_code in ["1", "2", "3", "4", "5"]
    println("Processing Goal $goal_code...")

    indicators = get_indicators(client, goal=goal_code)
    data = get_indicator_data(client, goal=goal_code)

    auto_export(data, "goal_$(goal_code)", format=:arrow)
end
```

## Performance Tips

1. **Use Caching**: Metadata is cached automatically. Use `force_refresh=false` (default) to avoid unnecessary API calls.

2. **Filter Early**: Specify `geoareas` and `time_period` to reduce data transfer:
   ```julia
   # Good: Specific query
   data = get_indicator_data(client, indicator="1.1.1", geoareas=["USA"], time_period=[2020])

   # Avoid: Fetching everything then filtering
   data = get_indicator_data(client, indicator="1.1.1")
   filtered = data[data.geoAreaCode .== "USA", :]
   ```

3. **Use Arrow Format**: For large datasets, Arrow format is fastest for both export and re-import:
   ```julia
   export_to_arrow(data, "data.arrow")

   # Later, quickly reload
   using Arrow
   data = DataFrame(Arrow.Table("data.arrow"))
   ```

4. **Batch Queries**: The client automatically handles pagination and rate limiting, so you can request large datasets without worry.

## Geographic Area Codes

Common area codes:
- `001` - World
- `002` - Africa
- `009` - Oceania
- `019` - Americas
- `142` - Asia
- `150` - Europe
- `USA` - United States
- `GBR` - United Kingdom
- `CHN` - China
- `JPN` - Japan

Use `get_geoareas(client)` to see all available codes.

## Data Structure

### Hierarchical Organization
```
SDG Goals (1-17)
├── Targets (e.g., 1.1, 1.2, ...)
    └── Indicators (e.g., 1.1.1, 1.1.2, ...)
        └── Series (specific data series)
            └── Data Points
                ├── Geographic dimension
                ├── Temporal dimension
                └── Disaggregation dimensions (sex, age, location, etc.)
```

### Common Disaggregation Dimensions
- **Sex**: MALE, FEMALE, BOTHSEX
- **Age**: Y0-14, Y15-24, Y25-64, Y65+
- **Location**: URBAN, RURAL, TOTAL
- **Wealth Quintile**: Q1, Q2, Q3, Q4, Q5

## Error Handling

The package includes robust error handling:
- Automatic retries with exponential backoff
- Rate limiting to respect API constraints
- Graceful handling of missing data
- Informative logging

## Contributing

Contributions are welcome! Please ensure:
- Descriptive variable names
- Composable and reusable code
- Proper error handling
- Documentation for new functions

## License

MIT License

## Related Resources

- [UN Stats SDG API Documentation](https://unstats.un.org/sdgapi/swagger/)
- [Sustainable Development Goals](https://sdgs.un.org/)
- [Julia DataFrames Documentation](https://dataframes.juliadata.org/)

## Examples Directory

See the `examples/` directory for more detailed usage examples:
- `basic_usage.jl` - Simple queries and exports
- `advanced_filtering.jl` - Complex filtering and aggregation
- `batch_processing.jl` - Processing multiple indicators
- `custom_reports.jl` - Building comprehensive reports
