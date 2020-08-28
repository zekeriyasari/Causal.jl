# This file includes the main test set of Causal. 
# To include new tests, write your tests in files and save them in directories under `test` directory.

using Test
using Causal

using Logging
using Random
using JLD2, FileIO
using UUIDs
using Statistics
using LightGraphs
# import Causal.process

# --------------------------- Deprecated -------------------------- 

function prepare(comp, kickoff::Bool=true)
    @warn "`prepare` function has been deprecated in favor of `equip`"
    equip(comp, kickoff) 
end 

# ---------------------------------- Include all test files --------------------- 

# Construct the file tree in `test` directory.
filetree = walkdir(@__DIR__)
take!(filetree) # Pop the root directory `test` in which `runtests.jl` is.

# Include all test files under `test`
@time @testset "CausalTestSet" begin
    for (root, dirs, files) in filetree
        foreach(file -> include(joinpath(root, file)), files)
    end
end
