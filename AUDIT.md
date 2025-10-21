# UNStatsExplorer CLI Audit

## Current Architecture

### Core Components

1. **Config (`config.jl`)** - 21 lines
   - Simple struct for API configuration
   - Handles: base_url, timeout, rate_limit_ms, max_retries, page_size
   - ✅ Clean and minimal

2. **Client (`client.jl`)** - 166 lines
   - HTTP client with rate limiting and retry logic
   - Caching mechanism for metadata
   - Pagination handling with progress bars
   - ✅ Well-structured, good error handling

3. **Metadata (`metadata.jl`)** - 156 lines
   - Functions: get_goals, get_targets, get_indicators, get_series, get_geoareas
   - Built-in caching with force_refresh option
   - search_indicators for keyword search
   - ✅ Comprehensive metadata access

4. **Data (`data.jl`)** - 169 lines
   - get_indicator_data with flexible filtering
   - get_series_data for specific series
   - compare_trends for trend analysis
   - ✅ Flexible querying

5. **Exports (`exports.jl`)** - 125 lines
   - Multiple format support: CSV, JSON, Arrow, Excel
   - Smart export based on extension
   - Auto-export with timestamps
   - Multi-sheet Excel exports
   - ✅ Comprehensive export options

6. **Explorer (`explorer.jl`)** - 263 lines
   - Interactive CLI menu system
   - **THIS IS WHERE COMPLEXITY LIES**

## CLI Explorer Analysis

### Current Flow
```
Main Menu
├── [g] Browse Goals
│   └── View goal → Explore indicators → Query data → Export
├── [i] Search Indicators
│   └── Display results (no further action)
├── [s] Query Series Data
│   └── Enter series code → Countries → Display → Export
├── [a] List Geographic Areas
│   └── Display → Optional export
├── [c] Compare Trends
│   └── Series code → Years → Areas → Display → Export
└── [q] Quit
```

### Pain Points Identified

#### 1. **User Experience Issues**
- **No auto-completion**: Users must know exact codes (e.g., "1.1.1", "USA")
- **No search before query**: Can't search for countries/series before entering codes
- **Limited navigation**: Can't easily go back or navigate between sections
- **No saved queries**: Must re-enter parameters for similar queries
- **Text-only input**: readline() doesn't support arrow keys or history

#### 2. **Code Complexity in CLI**
- **Deeply nested functions**: explore_goals → explore_goal_detail → explore_indicator_data
- **Repeated patterns**: Same export_choice logic in multiple places
- **String parsing**: Manual parsing of comma-separated inputs ("USA,GBR,JPN")
- **No input validation**: Doesn't validate codes before API calls
- **Mixed concerns**: Display, input handling, and business logic intertwined

#### 3. **Display Issues**
- **PrettyTables limitations**: Tables are cropped, hard to read long descriptions
- **No pagination**: Large result sets flood the screen
- **No color coding**: Everything looks the same
- **No summary statistics**: No quick overview of results

#### 4. **Missing Features**
- **No history**: Can't see what you queried before
- **No favorites**: Can't save commonly used indicators/countries
- **No query builder**: Must remember complex parameter combinations
- **No export preview**: Can't see what will be exported before exporting
- **No data visualization**: Just raw tables
- **No bulk operations**: Can't query multiple indicators at once

#### 5. **Error Handling**
- **Silent failures**: Some invalid inputs just return to menu
- **No suggestions**: Doesn't suggest corrections for invalid codes
- **Poor error messages**: Generic errors don't help users

### Current Strengths
- ✅ Comprehensive API coverage
- ✅ Good caching mechanism
- ✅ Multiple export formats
- ✅ Progress bars for long operations
- ✅ Rate limiting and retry logic
- ✅ Clean separation of concerns (except explorer)

### Complexity Metrics

| File | Lines | Functions | Complexity |
|------|-------|-----------|------------|
| config.jl | 21 | 1 | Low |
| client.jl | 166 | 4 | Medium |
| metadata.jl | 156 | 6 | Low |
| data.jl | 169 | 3 | Medium |
| exports.jl | 125 | 7 | Low |
| **explorer.jl** | **263** | **8** | **High** |

## Recommendations for Improvement

### High Priority
1. **Improve navigation** - Better menu system with breadcrumbs
2. **Add auto-completion** - Fuzzy search for codes and names
3. **Validation before API calls** - Check codes locally first
4. **Better error messages** - Actionable suggestions
5. **Separate concerns** - Extract input handling from business logic

### Medium Priority
6. **Interactive selectors** - Arrow-key navigation for choices
7. **Query history** - Save and recall previous queries
8. **Colored output** - Status indicators and highlighting
9. **Data preview** - Show sample before full query
10. **Bulk operations** - Query multiple items at once

### Low Priority
11. **Config file** - Save preferences and favorites
12. **Export presets** - Common export configurations
13. **Visualization** - Basic charts in terminal
14. **Filtering** - Post-query filtering of results
15. **Comparison mode** - Side-by-side comparisons

## Questions for Feedback

1. **Menu System**: Should we use a modern CLI framework (like Prompters.jl) or keep the simple readline approach?

2. **Data Display**: Should we implement paging for large datasets or stick with "show first N rows"?

3. **Input Method**: Would interactive prompts with arrow-key selection be better than typing codes?

4. **Query Builder**: Should we have a step-by-step wizard for complex queries?

5. **Caching Strategy**: Should we show cached vs. fresh data indicators?

6. **Export Workflow**: Should exports happen automatically or always prompt?

7. **Error Recovery**: How aggressive should we be with suggestions and auto-corrections?

8. **Code Organization**: Should explorer.jl be split into multiple files (menu.jl, input.jl, display.jl)?
