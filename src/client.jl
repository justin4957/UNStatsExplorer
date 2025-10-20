"""
Main client for interacting with UN SDG API with caching and rate limiting
"""
mutable struct SDGClient
    config::SDGConfig
    last_request_time::Float64
    cache::Dict{String, Any}
    headers::Dict{String, String}

    function SDGClient(config::SDGConfig=SDGConfig())
        headers = Dict(
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "Accept-Encoding" => "gzip"
        )
        new(config, 0.0, Dict{String, Any}(), headers)
    end
end

"""
Rate-limited HTTP GET request with exponential backoff retry logic
"""
function safe_get(client::SDGClient, endpoint::String, params::Dict=Dict())
    # Implement rate limiting
    elapsed_time = (time() - client.last_request_time) * 1000
    if elapsed_time < client.config.rate_limit_ms
        sleep((client.config.rate_limit_ms - elapsed_time) / 1000)
    end

    url = joinpath(client.config.base_url, endpoint)

    for attempt in 1:client.config.max_retries
        try
            response = HTTP.get(
                url,
                client.headers,
                query=params,
                readtimeout=client.config.timeout,
                retry=false
            )

            client.last_request_time = time()

            if response.status == 200
                return JSON3.read(String(response.body))
            else
                @warn "HTTP $(response.status) on attempt $attempt for $endpoint"
            end
        catch e
            if attempt == client.config.max_retries
                @error "Failed after $(client.config.max_retries) attempts" endpoint exception=e
                rethrow(e)
            end
            @warn "Attempt $attempt failed, retrying..." endpoint exception=e
            sleep(2^attempt)  # Exponential backoff
        end
    end

    error("Failed to complete request after $(client.config.max_retries) attempts")
end

"""
POST request for complex queries (e.g., compare trends)
"""
function safe_post(client::SDGClient, endpoint::String, body::Dict)
    elapsed_time = (time() - client.last_request_time) * 1000
    if elapsed_time < client.config.rate_limit_ms
        sleep((client.config.rate_limit_ms - elapsed_time) / 1000)
    end

    url = joinpath(client.config.base_url, endpoint)

    for attempt in 1:client.config.max_retries
        try
            response = HTTP.post(
                url,
                client.headers,
                JSON3.write(body),
                readtimeout=client.config.timeout,
                retry=false
            )

            client.last_request_time = time()

            if response.status == 200
                return JSON3.read(String(response.body))
            else
                @warn "HTTP $(response.status) on attempt $attempt"
            end
        catch e
            if attempt == client.config.max_retries
                @error "Failed after $(client.config.max_retries) attempts" exception=e
                rethrow(e)
            end
            @warn "Attempt $attempt failed, retrying..." exception=e
            sleep(2^attempt)
        end
    end

    error("Failed to complete request after $(client.config.max_retries) attempts")
end

"""
Fetch all pages of data with progress bar
"""
function fetch_all_pages(client::SDGClient, endpoint::String, params::Dict)
    all_data = []
    page = 1
    total_records = nothing

    params["pageSize"] = string(client.config.page_size)

    progress = nothing

    while true
        params["page"] = string(page)

        response = safe_get(client, endpoint, params)

        # Handle different response structures
        data = if haskey(response, :data)
            response.data
        elseif isa(response, Vector)
            response
        else
            []
        end

        if isempty(data)
            break
        end

        append!(all_data, data)

        # Initialize progress bar on first page
        if isnothing(total_records) && haskey(response, :totalRecords)
            total_records = response.totalRecords
            progress = Progress(total_records, desc="Fetching data: ")
        end

        if !isnothing(progress)
            update!(progress, length(all_data))
        end

        # Check if we've retrieved all data
        if haskey(response, :totalRecords) && length(all_data) >= response.totalRecords
            break
        end

        # If no totalRecords field, check if we got a full page
        if !haskey(response, :totalRecords) && length(data) < client.config.page_size
            break
        end

        page += 1
    end

    if !isnothing(progress)
        finish!(progress)
    end

    @info "Fetched $(length(all_data)) total records"

    return all_data
end
