# CLI Design Feedback & Recommendations

## Executive Summary

Based on the audit of UNStatsExplorer.jl, this document provides expert recommendations for improving the interactive CLI experience while maintaining Julia's strengths and minimizing complexity.

**Key Recommendation**: Incrementally improve the current readline()-based approach rather than introducing heavy framework dependencies. Focus on code organization, input validation, and progressive disclosure.

---

## 1. CLI Framework Decision

### Recommendation: **Enhanced readline() with selective improvements**

**Rationale:**
- **Julia's compilation time**: Adding frameworks increases startup time (critical for CLI tools)
- **Current simplicity**: The readline() approach works; it just needs refinement
- **Selective enhancement**: Add specific packages only where they provide clear value

**Recommended Packages (minimal set):**
- ✅ **Crayons.jl** - Color output (lightweight, ~50ms startup cost)
- ✅ **StringDistances.jl** - Fuzzy matching for validation (worthwhile UX improvement)
- ❌ **Term.jl** - Skip (heavy dependency, ~500ms+ startup)
- ❌ **REPL.TerminalMenus** - Consider for future if needed

**Implementation:**
```julia
using Crayons  # For colored output
using StringDistances  # For fuzzy search suggestions

# Lazy loading for rare operations
function get_term_menu()
    @eval using REPL.TerminalMenus
    return TerminalMenus
end
```

---

## 2. Code Organization

### Current Problem
- 263-line explorer.jl with mixed concerns
- Display, input handling, business logic all intertwined
- Hard to test and maintain

### Recommendation: **Module-based organization**

**New Structure:**
```
src/
├── explorer/
│   ├── menu.jl          # Menu state machine and navigation
│   ├── input.jl         # Input handling, validation, fuzzy matching
│   ├── display.jl       # Table formatting, pagination, colors
│   ├── state.jl         # Navigation state management
│   └── commands.jl      # Command pattern for actions
├── explorer.jl          # Main entry point, coordinates modules
└── ... (existing files)
```

**Benefits:**
- Single responsibility per module
- Easier testing
- Clear separation of concerns
- Can optimize compilation per module

**Example Pattern:**
```julia
# src/explorer/state.jl
mutable struct ExplorerState
    client::SDGClient
    navigation_stack::Vector{Symbol}  # [:main_menu, :goals, :goal_1]
    current_data::Union{DataFrame, Nothing}
    history::Vector{Dict}  # Query history
    breadcrumbs::Vector{String}
end

function push_nav!(state::ExplorerState, location::Symbol, label::String)
    push!(state.navigation_stack, location)
    push!(state.breadcrumbs, label)
end

function pop_nav!(state::ExplorerState)
    pop!(state.navigation_stack)
    pop!(state.breadcrumbs)
end

# src/explorer/menu.jl
function show_menu(state::ExplorerState)
    show_breadcrumbs(state)
    current_location = last(state.navigation_stack)

    if current_location == :main_menu
        show_main_menu()
    elseif current_location == :goals
        show_goals_menu(state)
    # ... etc
    end
end
```

---

## 3. Input Design & Validation

### Current Problems
- No validation before API calls
- Manual string parsing
- No suggestions for invalid input
- Poor error messages

### Recommendation: **Validation-first with fuzzy suggestions**

**Pattern:**
```julia
# src/explorer/input.jl

"""
Get user input with validation and fuzzy matching suggestions
"""
function get_validated_code(
    prompt::String,
    valid_codes::Vector{String},
    descriptions::Vector{String};
    allow_empty::Bool=false,
    fuzzy_threshold::Float64=0.6
)
    while true
        print(prompt)
        input = strip(readline())

        if allow_empty && isempty(input)
            return nothing
        end

        # Exact match
        if input in valid_codes
            idx = findfirst(==(input), valid_codes)
            println(Crayon(foreground=:green), "✓ Selected: $(descriptions[idx])", Crayon(reset=true))
            return input
        end

        # Fuzzy match suggestions
        suggestions = find_fuzzy_matches(input, valid_codes, descriptions, fuzzy_threshold)

        if !isempty(suggestions)
            println(Crayon(foreground=:yellow), "Did you mean:", Crayon(reset=true))
            for (i, (code, desc, score)) in enumerate(suggestions[1:min(5, end)])
                println("  [$i] $code - $desc ($(round(score*100))% match)")
            end
            println("  [r] Re-enter")

            choice = readline()
            if choice == "r"
                continue
            elseif (idx = tryparse(Int, choice)) !== nothing && 1 <= idx <= length(suggestions)
                return suggestions[idx][1]
            end
        else
            println(Crayon(foreground=:red), "✗ Invalid code: $input", Crayon(reset=true))
            println("Available codes: $(join(valid_codes[1:min(10, end)], ", "))...")
            println("Type 'list' to see all available codes, or try again:")
        end
    end
end

"""
Find fuzzy matches using Jaro-Winkler distance
"""
function find_fuzzy_matches(
    input::String,
    codes::Vector{String},
    descriptions::Vector{String},
    threshold::Float64
)
    matches = Tuple{String, String, Float64}[]

    for (code, desc) in zip(codes, descriptions)
        # Check code match
        code_score = compare(input, code, JaroWinkler())
        # Check description match (weighted lower)
        desc_score = compare(lowercase(input), lowercase(desc), JaroWinkler()) * 0.7

        max_score = max(code_score, desc_score)

        if max_score >= threshold
            push!(matches, (code, desc, max_score))
        end
    end

    return sort(matches, by=x->x[3], rev=true)
end

"""
Get multiple selections with validation
"""
function get_multi_select(
    prompt::String,
    valid_codes::Vector{String},
    descriptions::Vector{String}
)
    println(prompt)
    println("(Enter comma-separated values, or type 'all' for all options)")

    input = strip(readline())

    if lowercase(input) == "all"
        return valid_codes
    end

    selected = String[]
    parts = split(input, ",")

    for part in parts
        code = strip(part)
        if code in valid_codes
            push!(selected, code)
        else
            # Attempt fuzzy match
            matches = find_fuzzy_matches(code, valid_codes, descriptions, 0.8)
            if !isempty(matches)
                push!(selected, matches[1][1])
                println(Crayon(foreground=:yellow), "  ~ Auto-corrected '$code' to '$(matches[1][1])'", Crayon(reset=true))
            else
                println(Crayon(foreground=:red), "  ✗ Skipping invalid code: $code", Crayon(reset=true))
            end
        end
    end

    return selected
end
```

---

## 4. Display Improvements

### Current Problems
- Tables are cropped
- No color coding
- No pagination
- Hard to read long content

### Recommendation: **Smart pagination with colors**

**Implementation:**
```julia
# src/explorer/display.jl

using Crayons

const COLOR_HEADER = Crayon(foreground=:cyan, bold=true)
const COLOR_SUCCESS = Crayon(foreground=:green)
const COLOR_WARNING = Crayon(foreground=:yellow)
const COLOR_ERROR = Crayon(foreground=:red)
const COLOR_INFO = Crayon(foreground=:blue)
const COLOR_RESET = Crayon(reset=true)

"""
Display DataFrame with smart pagination and colors
"""
function display_table_smart(
    df::DataFrame;
    max_rows_per_page::Int=15,
    show_summary::Bool=true
)
    total_rows = nrow(df)

    if show_summary
        show_data_summary(df)
    end

    if total_rows == 0
        println(COLOR_WARNING, "No data to display", COLOR_RESET)
        return
    end

    if total_rows <= max_rows_per_page
        # Show all at once
        pretty_table(df,
            maximum_number_of_columns=10,
            header_crayon=COLOR_HEADER)
        return
    end

    # Paginated display
    current_page = 1
    total_pages = ceil(Int, total_rows / max_rows_per_page)

    while true
        println("\n", COLOR_HEADER, "═"^70, COLOR_RESET)
        println(COLOR_INFO, "Page $current_page of $total_pages ($(total_rows) total rows)", COLOR_RESET)
        println(COLOR_HEADER, "═"^70, COLOR_RESET)

        start_idx = (current_page - 1) * max_rows_per_page + 1
        end_idx = min(current_page * max_rows_per_page, total_rows)

        pretty_table(df[start_idx:end_idx, :],
            maximum_number_of_columns=10,
            header_crayon=COLOR_HEADER)

        println("\n", COLOR_INFO, "Navigation:", COLOR_RESET, " [n]ext [p]revious [f]irst [l]ast [q]uit [e]xport")
        print("> ")

        choice = lowercase(strip(readline()))

        if choice == "n" && current_page < total_pages
            current_page += 1
        elseif choice == "p" && current_page > 1
            current_page -= 1
        elseif choice == "f"
            current_page = 1
        elseif choice == "l"
            current_page = total_pages
        elseif choice == "q"
            break
        elseif choice == "e"
            return :export
        end
    end
end

"""
Show summary statistics for DataFrame
"""
function show_data_summary(df::DataFrame)
    println(COLOR_HEADER, "\n📊 Data Summary:", COLOR_RESET)
    println("  Rows: $(nrow(df))")
    println("  Columns: $(ncol(df))")

    # Show column types
    if ncol(df) > 0
        println("  Columns: $(join(names(df), ", "))")
    end

    # Show unique values for key columns
    for col in [:geoAreaName, :timePeriod, :indicator, :goal]
        if col in propertynames(df)
            unique_count = length(unique(df[!, col]))
            println("  Unique $col: $unique_count")
        end
    end
    println()
end

"""
Show breadcrumb navigation
"""
function show_breadcrumbs(state::ExplorerState)
    if isempty(state.breadcrumbs)
        return
    end

    println(COLOR_INFO, "📍 ", join(state.breadcrumbs, " > "), COLOR_RESET)
    println()
end
```

---

## 5. Error Handling & User Guidance

### Recommendation: **Proactive validation with helpful messages**

**Pattern:**
```julia
"""
Execute query with validation and helpful error messages
"""
function execute_query_safe(state::ExplorerState, query_fn::Function, params::Dict)
    try
        # Pre-flight validation
        validation_result = validate_query_params(state, params)

        if !validation_result.valid
            println(COLOR_ERROR, "✗ Query validation failed:", COLOR_RESET)
            for error in validation_result.errors
                println("  • $error")
            end

            if !isempty(validation_result.suggestions)
                println(COLOR_WARNING, "\n💡 Suggestions:", COLOR_RESET)
                for suggestion in validation_result.suggestions
                    println("  • $suggestion")
                end
            end

            return nothing
        end

        # Execute query with progress feedback
        println(COLOR_INFO, "⏳ Fetching data...", COLOR_RESET)
        result = query_fn(params...)

        println(COLOR_SUCCESS, "✓ Query successful", COLOR_RESET)
        return result

    catch e
        println(COLOR_ERROR, "✗ Error: $(sprint(showerror, e))", COLOR_RESET)

        # Provide contextual help
        if e isa HTTP.ExceptionRequest.StatusError
            if e.status == 404
                println(COLOR_WARNING, "💡 The requested data may not exist. Try:", COLOR_RESET)
                println("  • Checking the indicator code")
                println("  • Selecting a different time period")
                println("  • Choosing different geographic areas")
            elseif e.status >= 500
                println(COLOR_WARNING, "💡 Server error. The UN API may be experiencing issues.", COLOR_RESET)
                println("  • Try again in a few moments")
                println("  • Check https://unstats.un.org/sdgapi/swagger/ for API status")
            end
        end

        return nothing
    end
end
```

---

## 6. Navigation & State Management

### Recommendation: **Stack-based navigation with breadcrumbs**

**Pattern:**
```julia
# src/explorer/menu.jl

function interactive_explorer()
    state = ExplorerState(
        client=SDGClient(),
        navigation_stack=[:main_menu],
        current_data=nothing,
        history=[],
        breadcrumbs=["Main Menu"]
    )

    while true
        clear_screen()
        show_breadcrumbs(state)

        location = last(state.navigation_stack)

        action = if location == :main_menu
            handle_main_menu(state)
        elseif location == :goals
            handle_goals_menu(state)
        elseif location == :goal_detail
            handle_goal_detail(state)
        # ... other locations
        end

        if action == :back
            if length(state.navigation_stack) > 1
                pop_nav!(state)
            end
        elseif action == :quit
            println(COLOR_SUCCESS, "\nThank you for using UNStatsExplorer!", COLOR_RESET)
            break
        elseif action isa Tuple && action[1] == :navigate
            push_nav!(state, action[2], action[3])
        end
    end
end

function clear_screen()
    print("\033[2J\033[H")  # ANSI clear screen
end
```

---

## 7. Advanced Features - Priority Ranking

### High Priority (Implement First)
1. **Code organization refactor** - Split explorer.jl (1-2 days)
2. **Input validation with fuzzy search** - Before API calls (2-3 days)
3. **Colored output** - Add Crayons.jl (1 day)
4. **Smart pagination** - For large datasets (1-2 days)
5. **Breadcrumb navigation** - Stack-based with back button (1 day)

### Medium Priority (Next Sprint)
6. **Query history** - Save/recall previous queries (2 days)
7. **Configuration file** - ~/.unstatsexplorer/config.toml (2 days)
8. **Improved error messages** - Context-specific help (1 day)
9. **Data preview** - Show sample before full query (1 day)
10. **Export presets** - Saved export configurations (1 day)

### Low Priority (Future Enhancements)
11. **Bulk operations** - Multiple indicators at once (3 days)
12. **Saved favorites** - Bookmark indicators/countries (2 days)
13. **Query builder wizard** - Step-by-step complex queries (3-4 days)
14. **Terminal charts** - UnicodePlots.jl integration (2 days)
15. **Interactive menus** - REPL.TerminalMenus for selections (2 days)

---

## 8. Performance Considerations

### Julia Compilation Time Strategy

**Current startup time:** ~2-3 seconds (acceptable for CLI)

**Recommendations:**
1. **Keep core dependencies minimal** - Only add if significant UX benefit
2. **Lazy loading for rare operations** - Use `@eval using` pattern
3. **Precompilation** - Ensure proper `__precompile__()` declarations
4. **Package Compilation** - Use PackageCompiler.jl for deployment

**Recommended Dependencies (with justification):**
- ✅ HTTP, JSON3, DataFrames - Essential (already included)
- ✅ Crayons - ~50ms, huge UX benefit
- ✅ StringDistances - ~100ms, critical for fuzzy search
- ❌ Term.jl - ~500ms, too heavy for current needs
- ⚠️  REPL.TerminalMenus - Lazy load only if needed
- ⚠️  UnicodePlots - Lazy load for visualization features

**Example Lazy Loading:**
```julia
# Only load when visualization is requested
function show_chart(data::DataFrame)
    @eval using UnicodePlots
    # Create chart
end
```

---

## 9. Usability Principles

### Menu Depth
**Recommendation: Maximum 3-4 levels**

```
Level 1: Main Menu
├── Level 2: Browse Goals
│   └── Level 3: Goal Detail → Indicators
│       └── Level 4: Indicator Data Query
```

**Always provide:**
- Breadcrumbs showing current location
- Easy back navigation (type 'b' or 'back')
- Jump to main menu ('m' or 'menu')
- Quick exit ('q' or 'quit')

### Long-Running Operations
**Best Practices:**
1. **Show progress** - Use ProgressMeter (already implemented)
2. **Provide context** - "Fetching data for indicator 1.1.1..."
3. **Allow cancellation** - Catch Ctrl+C gracefully
4. **Cache results** - Avoid re-fetching same data
5. **Show time estimates** - "Fetching ~500 records..."

### Feature Discovery
**Make features obvious:**
1. **Help everywhere** - Always show available commands
2. **Examples** - Show example inputs in prompts
3. **Progressive disclosure** - Don't overwhelm with all options at once
4. **Tooltips in prompts** - "Enter indicator code (e.g., 1.1.1) or 'list' to see all:"

---

## 10. Implementation Roadmap

### Phase 1: Foundation (Week 1)
- [ ] Split explorer.jl into modules
- [ ] Add Crayons.jl for colored output
- [ ] Implement breadcrumb navigation
- [ ] Add input validation framework

### Phase 2: Polish (Week 2)
- [ ] Implement fuzzy search with StringDistances.jl
- [ ] Add smart pagination
- [ ] Improve error messages
- [ ] Add data summary statistics

### Phase 3: Features (Week 3)
- [ ] Query history
- [ ] Configuration file support
- [ ] Export presets
- [ ] Data preview mode

### Phase 4: Advanced (Week 4)
- [ ] Bulk operations
- [ ] Saved favorites
- [ ] Query builder wizard
- [ ] Optional: Terminal charts

---

## 11. Code Examples

### Example: Refactored Goal Exploration

**Before** (explorer.jl:23-38):
```julia
function explore_goals(client::SDGClient)
    goals = get_goals(client)
    println("\n" * "="^70)
    println("SDG GOALS ($(nrow(goals)) total)")
    println("="^70)
    display_table(goals)
    println("\nEnter goal code to explore (or 'back' to return): ")
    goal_code = readline()
    if goal_code != "back" && !isempty(goal_code)
        explore_goal_detail(client, goal_code)
    end
end
```

**After** (explorer/menu.jl):
```julia
function handle_goals_menu(state::ExplorerState)
    goals = get_goals(state.client)

    show_data_summary(goals)
    display_table_smart(goals, max_rows_per_page=17, show_summary=false)

    println(COLOR_INFO, "\nOptions:", COLOR_RESET)
    println("  [code] - Explore goal by code (e.g., '1', '2', '13')")
    println("  [list] - Show full list of goals")
    println("  [back] - Return to main menu")

    choice = get_validated_code(
        "\nEnter goal code: ",
        goals.code,
        goals.title,
        allow_empty=true
    )

    if choice === nothing
        return :back
    else
        state.current_goal = choice
        return (:navigate, :goal_detail, "Goal $choice")
    end
end
```

---

## Summary of Key Recommendations

1. **Keep readline(), enhance incrementally** - Don't add heavy frameworks
2. **Split explorer.jl into 4-5 focused modules** - Better organization
3. **Add Crayons.jl + StringDistances.jl only** - Minimal dependencies
4. **Validate before API calls** - Use cached metadata
5. **Implement fuzzy search** - Better error recovery
6. **Stack-based navigation** - With breadcrumbs and back button
7. **Smart pagination** - For large datasets
8. **Colored, helpful output** - Guide users effectively
9. **Progressive implementation** - 4-week roadmap
10. **Focus on usability** - Clear menus, good error messages, discoverable features

This approach balances UX improvements with Julia's performance characteristics and maintains code simplicity.
