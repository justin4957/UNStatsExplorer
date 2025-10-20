"""
Metadata retrieval functions with caching
"""

"""
Get list of all SDG goals (cached)
"""
function get_goals(client::SDGClient; force_refresh::Bool=false)
    cache_key = "goals"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Returning cached goals"
        return client.cache[cache_key]
    end

    @info "Fetching SDG goals from API..."
    response = safe_get(client, "v1/sdg/Goal/List")

    goals_df = DataFrame(
        code = [string(get(g, :code, missing)) for g in response],
        title = [get(g, :title, missing) for g in response],
        description = [get(g, :description, "") for g in response]
    )

    client.cache[cache_key] = goals_df
    @info "Cached $(nrow(goals_df)) goals"

    return goals_df
end

"""
Get list of all targets (cached)
"""
function get_targets(client::SDGClient; goal::Union{String,Nothing}=nothing, force_refresh::Bool=false)
    cache_key = "targets_$(something(goal, "all"))"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Returning cached targets"
        return client.cache[cache_key]
    end

    @info "Fetching targets..." goal
    params = isnothing(goal) ? Dict{String,String}() : Dict("goal" => goal)
    response = safe_get(client, "v1/sdg/Target/List", params)

    targets_df = DataFrame(
        code = [string(get(t, :code, missing)) for t in response],
        goal = [string(get(t, :goal, missing)) for t in response],
        title = [get(t, :title, missing) for t in response],
        description = [get(t, :description, "") for t in response]
    )

    client.cache[cache_key] = targets_df
    @info "Cached $(nrow(targets_df)) targets"

    return targets_df
end

"""
Get list of all indicators with filtering options (cached)
"""
function get_indicators(client::SDGClient; goal::Union{String,Nothing}=nothing, force_refresh::Bool=false)
    cache_key = "indicators_$(something(goal, "all"))"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Returning cached indicators"
        return client.cache[cache_key]
    end

    @info "Fetching indicators..." goal
    params = isnothing(goal) ? Dict{String,String}() : Dict("goal" => goal)
    response = safe_get(client, "v1/sdg/Indicator/List", params)

    indicators_df = DataFrame(
        code = [string(get(i, :code, missing)) for i in response],
        goal = [string(get(i, :goal, missing)) for i in response],
        target = [string(get(i, :target, missing)) for i in response],
        description = [get(i, :description, "") for i in response]
    )

    client.cache[cache_key] = indicators_df
    @info "Cached $(nrow(indicators_df)) indicators"

    return indicators_df
end

"""
Get list of all data series (cached)
"""
function get_series(client::SDGClient; indicator::Union{String,Nothing}=nothing, force_refresh::Bool=false)
    cache_key = "series_$(something(indicator, "all"))"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Returning cached series"
        return client.cache[cache_key]
    end

    @info "Fetching series..." indicator
    params = isnothing(indicator) ? Dict{String,String}() : Dict("indicator" => indicator)
    response = safe_get(client, "v1/sdg/Series/List", params)

    series_df = DataFrame(
        code = [string(get(s, :code, missing)) for s in response],
        description = [get(s, :description, "") for s in response],
        indicator = [get(s, :indicator, missing) for s in response],
        goal = [get(s, :goal, missing) for s in response],
        target = [get(s, :target, missing) for s in response]
    )

    client.cache[cache_key] = series_df
    @info "Cached $(nrow(series_df)) series"

    return series_df
end

"""
Get list of geographic areas (cached)
"""
function get_geoareas(client::SDGClient; force_refresh::Bool=false)
    cache_key = "geoareas"

    if !force_refresh && haskey(client.cache, cache_key)
        @info "Returning cached geographic areas"
        return client.cache[cache_key]
    end

    @info "Fetching geographic areas from API..."
    response = safe_get(client, "v1/sdg/GeoArea/List")

    geoareas_df = DataFrame(
        geoAreaCode = [string(get(g, :geoAreaCode, missing)) for g in response],
        geoAreaName = [get(g, :geoAreaName, missing) for g in response],
        geoAreaType = [get(g, :geoAreaType, missing) for g in response]
    )

    client.cache[cache_key] = geoareas_df
    @info "Cached $(nrow(geoareas_df)) geographic areas"

    return geoareas_df
end

"""
Search indicators by keyword in description
"""
function search_indicators(client::SDGClient, keyword::String; goal::Union{String,Nothing}=nothing)
    indicators = get_indicators(client, goal=goal)

    keyword_lower = lowercase(keyword)
    mask = [occursin(keyword_lower, lowercase(desc)) for desc in indicators.description]

    results = indicators[mask, :]
    @info "Found $(nrow(results)) indicators matching '$keyword'"

    return results
end
