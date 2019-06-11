# This file is for Simulation object.


mutable struct Simulation{M, L} <: AbstractSimulation
    model::M
    path::String
    logger::L
    status::Symbol
    retcode::Symbol
    name::String
    function Simulation(model, simdir, logger)
        name = join(["Simulation-", string(uuid4())], "")  # `get_instant()` may be used for time-based paths names.
        path = joinpath(simdir, name)
        isdir(path) || mkpath(path)
        check_writer_files(model, path, force=true)
        new{typeof(model), typeof(logger)}(model, path, logger, :idle, :unknown, name)
    end
end
Simulation(model; simdir=DEFAULTS[:WRITER_PATHS], logger=SimpleLogger()) = Simulation(model, simdir, logger)

##### Simulation checks

function check_writer_files(model, path; force=true)
    for writer in filter(block -> isa(block, Writer), model.blocks)
        dirname(writer.file.path) == path || mv(writer, path, force=true)
    end
end

##### Simulation logging

function setlogger(path, name; setglobal::Bool=true)
    io = open(joinpath(path, name), "w+")
    logger = SimpleLogger(io)
    if setglobal
        global_logger(logger)
    end
    logger
end

function closelogger(logger=global_logger())
    if isa(logger, AbstractLogger)
        close(logger.stream)
    end
end

##### Simulation reporting

function report(simulation)
    # Write simulation info.
    jldopen(joinpath(simulation.path, "report.jld2"), "w") do simreport
        simreport["name"] = simulation.name
        simreport["path"] = simulation.path
        simreport["status"] = simulation.status
        simreport["retcode"] = simulation.retcode
        
        # Save simulation model blocks.
        foreach(delete_callback, filter(block->isa(block, AbstractSink), simulation.model.blocks))
        # foreach(delete_sink_callback, filter(block->isa(block, AbstractSink), simulation.model.blocks))
        model_group = JLD2.Group(simreport, "model")
        model_group["name"] = simulation.model.name
        model_group["clk"] = simulation.model.clk
        model_group["callbacks"] = simulation.model.callbacks
        model_blocks_group = JLD2.Group(simreport, "blocks")
        for block in filter(block->!isa(block, Writer), simulation.model.blocks)
            model_blocks_group[block.name] = block
        end
    end
    # close(simreport)
end

##### SimulationError type

struct SimulationError <: Exception
    msg::String
end
Base.showerror(io::IO, err::SimulationError) = println(io, err.msg)
