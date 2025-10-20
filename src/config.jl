"""
Configuration for SDG API client with rate limiting and retry logic
"""
struct SDGConfig
    base_url::String
    timeout::Int
    rate_limit_ms::Int
    max_retries::Int
    page_size::Int

    function SDGConfig(;
        base_url="https://unstats.un.org/sdgapi",
        timeout=30,
        rate_limit_ms=500,
        max_retries=3,
        page_size=1000
    )
        new(base_url, timeout, rate_limit_ms, max_retries, page_size)
    end
end
