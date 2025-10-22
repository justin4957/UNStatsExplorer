module UNStatsExplorer

using HTTP
using JSON3
using DataFrames
using Dates
using CSV
using PrettyTables
using ProgressMeter
using Arrow
using XLSX
using JSONTables
using StringDistances
using Crayons

export SDGClient, SDGConfig
export get_goals, get_indicators, get_series, get_geoareas, get_targets
export get_indicator_data, get_series_data, compare_trends
export export_to_csv, export_to_json, export_to_arrow, export_to_xlsx
export export_data, auto_export, export_multi_sheet_xlsx
export interactive_explorer, search_indicators

include("config.jl")
include("client.jl")
include("country_codes.jl")
include("metadata.jl")
include("data.jl")
include("exports.jl")
include("explorer.jl")

end
