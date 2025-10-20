"""
Data retrieval functions for SDG indicators and series
"""

"""
Get indicator data with flexible filtering and pagination
"""
function get_indicator_data(
    client::SDGClient;
    indicator::Union{String,Nothing}=nothing,
    goal::Union{String,Nothing}=nothing,
    geoareas::Union{Vector{String},Nothing}=nothing,
    time_period::Union{Vector{Int},Nothing}=nothing,
    series::Union{String,Nothing}=nothing
)
    params = Dict{String,String}()

    !isnothing(indicator) && (params["indicator"] = indicator)
    !isnothing(goal) && (params["goal"] = goal)
    !isnothing(series) && (params["series"] = series)

    if !isnothing(geoareas)
        params["geoAreaCode"] = join(geoareas, ",")
    end

    if !isnothing(time_period)
        params["timePeriod"] = join(time_period, ",")
    end

    @info "Fetching indicator data..." params

    data = fetch_all_pages(client, "v1/sdg/Indicator/Data", params)

    if isempty(data)
        @warn "No data returned for query"
        return DataFrame()
    end

    # Convert to DataFrame with robust handling of missing fields
    df = DataFrame(
        goal = [string(get(d, :goal, missing)) for d in data],
        target = [string(get(d, :target, missing)) for d in data],
        indicator = [string(get(d, :indicator, missing)) for d in data],
        series = [string(get(d, :series, missing)) for d in data],
        seriesDescription = [get(d, :seriesDescription, missing) for d in data],
        geoAreaCode = [string(get(d, :geoAreaCode, missing)) for d in data],
        geoAreaName = [get(d, :geoAreaName, missing) for d in data],
        timePeriod = [get(d, :timePeriod, missing) for d in data],
        value = [get(d, :value, missing) for d in data],
        units = [get(d, :units, missing) for d in data],
        nature = [get(d, :nature, missing) for d in data],
        source = [get(d, :source, missing) for d in data]
    )

    @info "Retrieved $(nrow(df)) data points"

    return df
end

"""
Get series data (more specific than indicator data)
"""
function get_series_data(
    client::SDGClient;
    series::String,
    geoareas::Union{Vector{String},Nothing}=nothing,
    time_period::Union{Vector{Int},Nothing}=nothing
)
    params = Dict{String,String}("series" => series)

    if !isnothing(geoareas)
        params["geoAreaCode"] = join(geoareas, ",")
    end

    if !isnothing(time_period)
        params["timePeriod"] = join(time_period, ",")
    end

    @info "Fetching series data..." series

    data = fetch_all_pages(client, "v1/sdg/Series/Data", params)

    if isempty(data)
        @warn "No data returned for series" series
        return DataFrame()
    end

    # Convert to DataFrame
    df = DataFrame(
        series = [string(get(d, :series, missing)) for d in data],
        seriesDescription = [get(d, :seriesDescription, missing) for d in data],
        geoAreaCode = [string(get(d, :geoAreaCode, missing)) for d in data],
        geoAreaName = [get(d, :geoAreaName, missing) for d in data],
        timePeriod = [get(d, :timePeriod, missing) for d in data],
        value = [get(d, :value, missing) for d in data],
        units = [get(d, :units, missing) for d in data],
        nature = [get(d, :nature, missing) for d in data],
        source = [get(d, :source, missing) for d in data]
    )

    # Parse dimension attributes if present
    if any(haskey(d, :dimensions) for d in data)
        for d in data
            if haskey(d, :dimensions) && !isnothing(d.dimensions)
                for dim in d.dimensions
                    dim_id = get(dim, :dimensionId, "unknown")
                    dim_value = get(dim, :dimensionItemName, "")
                    # Could expand dimensions into separate columns here
                end
            end
        end
    end

    @info "Retrieved $(nrow(df)) series data points"

    return df
end

"""
Compare trends across global, regional, and country levels with disaggregation
"""
function compare_trends(
    client::SDGClient;
    series_code::String,
    years::Vector{Int}=Int[],
    area_codes::Vector{String}=["001"],
    dimensions::Vector{Dict}=Dict[]
)
    body = Dict(
        "seriesCode" => series_code,
        "years" => years,
        "areaCodes" => area_codes,
        "dimensions" => dimensions
    )

    @info "Comparing trends..." series_code years area_codes

    response = safe_post(client, "v1/sdg/CompareTrends/DisaggregatedGlobalAndRegional", body)

    # Handle response structure
    data = if haskey(response, :data)
        response.data
    elseif isa(response, Vector)
        response
    else
        []
    end

    if isempty(data)
        @warn "No trend comparison data returned"
        return DataFrame()
    end

    # Convert to DataFrame
    df = DataFrame(
        seriesCode = [string(get(d, :seriesCode, missing)) for d in data],
        geoAreaCode = [string(get(d, :geoAreaCode, missing)) for d in data],
        geoAreaName = [get(d, :geoAreaName, missing) for d in data],
        timePeriod = [get(d, :timePeriod, missing) for d in data],
        value = [get(d, :value, missing) for d in data],
        nature = [get(d, :nature, missing) for d in data],
        source = [get(d, :source, missing) for d in data]
    )

    @info "Retrieved $(nrow(df)) trend comparison data points"

    return df
end
