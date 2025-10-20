#!/usr/bin/env julia

"""
Launch the interactive UN Stats Explorer
"""

using Pkg

# Ensure we're in the right environment
cd(@__DIR__)
Pkg.activate(".")

println("Checking dependencies...")
Pkg.instantiate()

println("Loading UNStatsExplorer...")
using UNStatsExplorer

# Launch interactive explorer
interactive_explorer()
