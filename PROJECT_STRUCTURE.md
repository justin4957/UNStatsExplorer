# UNStatsExplorer Project Structure

## Overview

A comprehensive Julia package for exploring UN Stats SDG (Sustainable Development Goals) data with minimal overhead and maximum flexibility.

## Directory Structure

```
UNStatsExplorer/
├── Project.toml              # Package dependencies and metadata
├── README.md                 # Comprehensive documentation
├── QUICKSTART.md            # Quick start guide
├── PROJECT_STRUCTURE.md     # This file
├── run_explorer.jl          # Launch interactive explorer (executable)
├── .gitignore               # Git ignore rules
│
├── src/                     # Core package source code
│   ├── UNStatsExplorer.jl  # Main module (exports all functions)
│   ├── config.jl           # Configuration struct and defaults
│   ├── client.jl           # HTTP client with rate limiting and retries
│   ├── metadata.jl         # Goals, indicators, series, areas retrieval
│   ├── data.jl             # Data fetching and querying functions
│   ├── exports.jl          # Export utilities (CSV, JSON, Arrow, Excel)
│   └── explorer.jl         # Interactive CLI interface
│
└── examples/                # Usage examples
    ├── quick_start.jl      # Get started immediately
    ├── basic_usage.jl      # Simple queries and exports
    ├── advanced_filtering.jl  # Complex analysis patterns
    └── batch_processing.jl    # Batch operations and reports
```

## Core Components

### 1. Configuration (`config.jl`)
- `SDGConfig`: Configurable API settings
  - Base URL
  - Timeout duration
  - Rate limiting
  - Retry logic
  - Page size for pagination

### 2. Client (`client.jl`)
- `SDGClient`: Main client with caching
- `safe_get()`: Rate-limited GET with retry
- `safe_post()`: Rate-limited POST with retry
- `fetch_all_pages()`: Automatic pagination handler

### 3. Metadata (`metadata.jl`)
- `get_goals()`: Fetch SDG goals (17 total)
- `get_targets()`: Fetch SDG targets (169 total)
- `get_indicators()`: Fetch SDG indicators (231+ total)
- `get_series()`: Fetch data series
- `get_geoareas()`: Fetch geographic areas
- `search_indicators()`: Keyword search

### 4. Data Retrieval (`data.jl`)
- `get_indicator_data()`: Main data fetching function
  - Filter by indicator, goal, countries, years
  - Automatic pagination
  - Progress tracking
- `get_series_data()`: Fetch specific series data
- `compare_trends()`: Compare global/regional trends

### 5. Export Utilities (`exports.jl`)
- `export_to_csv()`: Export to CSV format
- `export_to_json()`: Export to JSON format
- `export_to_arrow()`: Export to Apache Arrow (efficient binary)
- `export_to_xlsx()`: Export to Excel format
- `export_data()`: Smart export (auto-detects format)
- `auto_export()`: Auto-generate filename with timestamp
- `export_multi_sheet_xlsx()`: Multi-sheet Excel exports

### 6. Interactive Explorer (`explorer.jl`)
- `interactive_explorer()`: Launch CLI menu interface
- `explore_goals()`: Browse goals interactively
- `explore_goal_detail()`: Drill into specific goal
- `explore_indicator_data()`: Query indicator data
- `filtered_query()`: Build filtered queries interactively
- `display_table()`: Pretty-print DataFrames

## Key Features

### 🚀 Performance Optimizations
- **Automatic Caching**: Metadata cached to reduce API calls
- **Smart Pagination**: Handles large datasets automatically
- **Rate Limiting**: Respects API constraints
- **Retry Logic**: Exponential backoff for failed requests
- **Progress Bars**: Visual feedback for long operations

### 📊 Data Export
- **Multiple Formats**: CSV, JSON, Arrow, Excel
- **Batch Processing**: Process multiple goals/indicators
- **Multi-Sheet Excel**: Comprehensive reports
- **Auto-Naming**: Timestamp-based filenames

### 🔍 Query Flexibility
- Filter by goals, targets, indicators, series
- Filter by countries/regions (geographic areas)
- Filter by time periods (years)
- Support for disaggregated data
- Keyword search across indicators

### 🎨 User Experience
- Interactive menu-driven explorer
- Pretty-printed tables
- Informative logging
- Robust error handling
- Type-safe operations

## Data Flow

```
User Request
    ↓
SDGClient (with cache check)
    ↓
safe_get/safe_post (rate-limited, retry logic)
    ↓
UN Stats API
    ↓
fetch_all_pages (automatic pagination)
    ↓
JSON3 parsing
    ↓
DataFrame conversion
    ↓
Export utilities → CSV/JSON/Arrow/Excel
```

## Dependencies

Core dependencies specified in `Project.toml`:

- **HTTP.jl**: HTTP client for API requests
- **JSON3.jl**: Fast JSON parsing
- **DataFrames.jl**: Tabular data manipulation
- **CSV.jl**: CSV export
- **Arrow.jl**: Apache Arrow format (efficient binary)
- **XLSX.jl**: Excel format
- **JSONTables.jl**: JSON export with table structure
- **PrettyTables.jl**: Console table formatting
- **ProgressMeter.jl**: Progress bars
- **Dates**: Date/time handling (stdlib)
- **REPL**: REPL utilities (stdlib)

## Usage Patterns

### Pattern 1: Quick Query and Export
```julia
client = SDGClient()
data = get_indicator_data(client, indicator="1.1.1", time_period=[2020])
export_to_csv(data, "output.csv")
```

### Pattern 2: Batch Processing
```julia
for goal in ["1", "2", "3"]
    data = get_indicator_data(client, goal=goal)
    auto_export(data, "goal_$goal", format=:arrow)
end
```

### Pattern 3: Interactive Exploration
```julia
interactive_explorer()  # Menu-driven interface
```

### Pattern 4: Complex Reports
```julia
goals = get_goals(client)
indicators = get_indicators(client, goal="13")
data = get_indicator_data(client, goal="13")

export_multi_sheet_xlsx(
    Dict("Goals" => goals, "Indicators" => indicators, "Data" => data),
    "report.xlsx"
)
```

## API Endpoint Mapping

| Function | API Endpoint |
|----------|-------------|
| `get_goals()` | `/v1/sdg/Goal/List` |
| `get_targets()` | `/v1/sdg/Target/List` |
| `get_indicators()` | `/v1/sdg/Indicator/List` |
| `get_series()` | `/v1/sdg/Series/List` |
| `get_geoareas()` | `/v1/sdg/GeoArea/List` |
| `get_indicator_data()` | `/v1/sdg/Indicator/Data` |
| `get_series_data()` | `/v1/sdg/Series/Data` |
| `compare_trends()` | `/v1/sdg/CompareTrends/DisaggregatedGlobalAndRegional` |

## Design Principles

1. **Composability**: Functions are small, focused, and composable
2. **Reusability**: Core utilities can be used independently
3. **Descriptive Naming**: Clear, self-documenting function names
4. **Type Safety**: Robust handling of missing data and type conversions
5. **Minimal Overhead**: Efficient data structures and caching
6. **Easy Export**: Multiple format support for different use cases
7. **Progressive Disclosure**: Simple interface with advanced options available
8. **Fail-Safe**: Graceful error handling with informative messages

## Extension Points

Easy to extend for custom needs:

1. **Add New Export Formats**: Extend `exports.jl`
2. **Custom Queries**: Build on `data.jl` functions
3. **Analysis Functions**: Process DataFrames with standard Julia tools
4. **Visualization**: Pipe exported data to plotting libraries
5. **Custom Caching**: Extend `SDGClient` cache mechanism

## Getting Started

1. **Quick Test**: `julia examples/quick_start.jl`
2. **Interactive**: `julia run_explorer.jl`
3. **Custom Script**: See examples directory

## Performance Benchmarks

Expected performance (actual may vary based on network):

- Metadata retrieval: < 2 seconds (cached after first call)
- Single indicator query (10 years): 2-5 seconds
- Full goal data: 10-60 seconds (depends on data volume)
- Export to Arrow: Fastest (binary format)
- Export to CSV: Fast (universal compatibility)
- Export to Excel: Moderate (formatting overhead)

## Contributing

When extending this package:

1. Follow existing naming conventions
2. Add docstrings to new functions
3. Update README.md with new features
4. Add examples for complex functionality
5. Maintain composability and reusability
6. Test with various query parameters

## Resources

- [UN Stats API Documentation](https://unstats.un.org/sdgapi/swagger/)
- [SDG Indicators](https://unstats.un.org/sdgs/indicators/indicators-list/)
- [Julia DataFrames Documentation](https://dataframes.juliadata.org/)
- [HTTP.jl Documentation](https://juliaweb.github.io/HTTP.jl/)

---

**Built with**: Julia 1.9+
**License**: MIT
**Status**: Production-ready for exploring and exporting UN SDG data
