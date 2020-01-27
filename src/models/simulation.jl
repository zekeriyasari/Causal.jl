# This file is for Simulation object.

"""
    Simulation(model, simdir=DEFAULTS[:WRITER_PATHS], logger=SimpleLogger())

Constructs a `Simulation` object for the simulation of `model`. The `Simulation` object is used to monitor the state of the simulation of the `model`. `simdir` is the path of the directory into which the simulation files(log, data files etc.) are recorded. `logger` is used to log the simulation steps of the `model`. See also: [`Model`](@ref), [`Logging`](https://docs.julialang.org/en/v1/stdlib/Logging/)
"""
mutable struct Simulation{M, L}
    model::M
    path::String
    logger::L
    state::Symbol
    retcode::Symbol
    name::String
    function Simulation(model, simdir=tempdir(), logger=SimpleLogger())
        name = join(["Simulation-", string(uuid4())], "")  # `get_instant()` may be used for time-based paths names.
        path = joinpath(simdir, name)
        isdir(path) || mkpath(path)
        check_writer_files(model, path, force=true)
        new{typeof(model), typeof(logger)}(model, path, logger, :idle, :unknown, name)
    end
end

show(io::IO, sim::Simulation) = print(io, "Simulation(state:$(sim.state), retcode:$(sim.retcode), path:$(sim.path))")

##### Simulation checks

function check_writer_files(model, path; force=true)
    for writer in filter(block -> isa(block, Writer), model.blocks)
        dirname(writer.file.path) == path || mv(writer, path, force=true)
    end
end

##### Simulation logging
"""
    setlogger(path, name; setglobal::Bool=true)

Returns a logger. `path` is the path and `name` is the name of the file of the logger. If `setglobal` is `true`, the returned logger is a global logger.

# Example 
```jldoctest 
julia> logger = setlogger(tempdir(), "mylogger", setglobal=true)
Base.CoreLogging.SimpleLogger(IOStream(<file /tmp/mylogger>), Info, Dict{Any,Int64}())
```
"""
function setlogger(path::AbstractString, name::AbstractString; setglobal::Bool=true)
    io = open(joinpath(path, name), "w+")
    logger = SimpleLogger(io)
    if setglobal
        global_logger(logger)
    end
    logger
end

"""
    closelogger(logger=global_logger())

Closes the `logger` the file of the `loggger`. See also: [`setlogger`](@ref)
"""
function closelogger(logger=global_logger())
    if isa(logger, AbstractLogger)
        close(logger.stream)
    end
end

##### Simulation reporting
"""
    report(simulation::Simulation)

Records the state of the `simulation` by writing all its fields into a data file. All the fields of the `simulation` is written into file. When the file is read back, the `simulation` object is constructed back. The data file is written under the path of the `simulation`.
"""
function report(simulation::Simulation)
    # Write simulation info.
    jldopen(joinpath(simulation.path, "report.jld2"), "w") do simreport
        simreport["name"] = simulation.name
        simreport["path"] = simulation.path
        simreport["state"] = simulation.state
        simreport["retcode"] = simulation.retcode
        
        # Save simulation model blocks.
        foreach(deleteplugin, filter(block->isa(block, AbstractSink), simulation.model.blocks))
        # foreach(delete_sink_callback, filter(block->isa(block, AbstractSink), simulation.model.blocks))
        model_group = JLD2.Group(simreport, "model")
        model_group["name"] = string(simulation.model.id)
        model_group["clk"] = simulation.model.clk
        model_group["callbacks"] = simulation.model.callbacks
        model_blocks_group = JLD2.Group(simreport, "blocks")
        for block in filter(block->!isa(block, Writer), simulation.model.blocks)
            model_blocks_group[string(block.id)] = block
        end
    end
    # close(simreport)
end

##### SimulationError type
"""
    SimulationError(msg::String)

Thrown when an error occurs during a simulation.
"""
struct SimulationError <: Exception
    msg::String
end
Base.showerror(io::IO, err::SimulationError) = println(io, err.msg)
