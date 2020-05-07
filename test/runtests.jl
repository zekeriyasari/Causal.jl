# This file includes the main test set of Jusdl. 
# To include new tests, write your tests in files and save them in directories under `test` directory.

using Test
using Jusdl

using DifferentialEquations
using Logging
using Random
using JLD2, FileIO
using UUIDs
using Statistics
using LightGraphs
import Jusdl.process

launchport(iport) = @async while true 
    all(take!(iport) .=== NaN) && break 
end

function prepare(comp, kickoff::Bool=true)
    oport = typeof(comp) <: AbstractSource ? 
        nothing : (typeof(comp.input) === nothing  ? nothing : Outport(length(comp.input)))
    iport = typeof(comp) <: AbstractSink ?  
        nothing : (typeof(comp.output) === nothing ? nothing : Inport(length(comp.output)))
    trg = Outpin()
    hnd = Inpin{Bool}()
    oport === nothing || connect!(oport, comp.input)
    iport === nothing || connect!(comp.output, iport)
    connect!(trg, comp.trigger)
    connect!(comp.handshake, hnd)
    if kickoff 
        comptask, outputtask = launch(comp), launchport(iport)
    else 
        comptask, outputtask = nothing, nothing
    end
    oport, iport, trg, hnd, comptask, outputtask
end


# Construct the file tree in `test` directory.
filetree = walkdir(@__DIR__)
take!(filetree) # Pop the root directory `test` in which `runtests.jl` is.

# Include all test files under `test`
@time @testset "JusdlTestSet" begin
    for (root, dirs, files) in filetree
        foreach(file -> include(joinpath(root, file)), files)
    end
end
