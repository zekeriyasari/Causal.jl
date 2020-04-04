# This file includes the Model object
import Base: getindex

"""
    Model(components::AbstractVector)

Constructs a `Model` whose with components `components` which are of type `AbstractComponent`.

    Model()

Constructs a `Model` with empty components. After the construction, components can be added to `Model`.

!!! warning
    `Model`s are units that can be simulated. As the data flows through the connections i.e. input output busses of the components, its is important that the components must be connected to each other. See also: [`simulate`](@ref)
"""
mutable struct Model{GR, CK, TM, CB}
    graph::GR
    clock::CK
    taskmanager::TM
    callbacks::CB
    name::Symbol
    id::UUID
    function Model(components::AbstractVector; clock=Clock(0, 0.01, 1.), callbacks=nothing, name=Symbol())
        graph = MetaDiGraph(SimpleDiGraph())
        taskmanager = TaskManager()
        model = new{typeof(graph), typeof(clock), typeof(taskmanager), typeof(callbacks)}(graph, clock, taskmanager, 
            callbacks, name, uuid4())
        set_indexing_prop!(graph, :name)
        addcomponent(model, components...)
        model
    end
end
Model(components::AbstractComponent...; kwargs...) = Model([components...]; kwargs...)
Model(;kwargs...) = Model([]; kwargs...)

show(io::IO, model::Model) = print(io, 
    "Model(numcomponents:$(numcomponents(model)), numconnections:$(numconnections(model)), timesettings=($(model.clock.t), $(model.clock.dt), $(model.clock.tf)))")

gplot(model::Model) = gplot(model.graph, nodelabel=map(i -> getname(model, i),  vertices(model.graph)))

numcomponents(model::Model) = nv(model.graph)
numconnections(model::Model) = ne(model.graph)

##### Modifying model 
getindex(model::Model, name::Symbol) = model.graph[name, :name]
getname(model, idx::Int) = getfield(getcomponent(model, idx), :name)
getcomponent(model::Model, name::Symbol) = get_prop(model.graph, model[name], :component)
getcomponent(model::Model, idx::Int) = get_prop(model.graph, idx, :component)
getcomponents(model) = map(idx -> getcomponent(model, idx), vertices(model.graph))
getconnection(model::Model, srcname::Symbol, dstname::Symbol) = get_prop(model.graph, model[srcname], model[dstname], :connection)

function addcomponent(model::Model, components::AbstractComponent...)
    taskmanager = model.taskmanager
    graph = model.graph 
    n = nv(graph)
    for (k, component) in enumerate(components)
        add_vertex!(graph, :component, component)
        set_indexing_prop!(graph, n + k, :name, component.name)
        record(taskmanager, component) 
    end 
end

function addconnection(model::Model, srcname, dstname, srcidx=nothing, dstidx=nothing)
    src, dst = model[srcname], model[dstname]
    srccomp, dstcomp = getcomponent(model, src), getcomponent(model, dst)
    outport = srcidx === nothing ? srccomp.output : srccomp.output[srcidx]
    inport = dstidx === nothing ? dstcomp.input : dstcomp.input[dstidx]
    add_edge!(model.graph, src, dst, :connection, connect(outport, inport))
end

function record(taskmanager, component)
    triggerport, handshakeport = taskmanager.triggerport, taskmanager.handshakeport
    triggerpin, handshakepin = Outpin(), Inpin{Bool}()
    connect(triggerpin, component.trigger)
    connect(component.handshake, handshakepin)
    push!(triggerport.pins, triggerpin)
    push!(handshakeport.pins, handshakepin)
    taskmanager.pairs[component] = nothing
end

##### Model inspection.
getloops(model::Model) = simplecycles(model.graph)
hasmemory(model, loop) = any(isa.(map(idx -> getcomponent(model, idx), loop), AbstractMemory))
function hasloops(model::Model)
    loops = getloops(model)
    isempty(loops) && return false
    return any(map(loop -> !hasmemory(model, loop), loops))
end
breakloop(model::Model, loops) = nothing

"""
    inspect(model::Model)

Inspects the `model`. If `model` has some inconsistencies such as including algebraic loops or unterminated busses and error is thrown.
"""
function inspect(model)
    if hasloops(model)
        loops = getloops(model)
        names = map(loop -> map(comp -> getname(model, comp), loop), loops)
        msg = "Simulation aborted. The model has algrebraic loops: $names."
        msg *= "For the simulation to continue, break these loops"
        @error msg
        while !isempty(loops)
            loop = pop!(loops)
            try 
                breakloop(model, loop)
            catch
                error("Algebric loops:$loop could not be broken.")
            end
        end
    end
end

##### Model initialization
"""
    initialize(model::Model)

Initializes `model` by launching component task for each of the component of `model`. The pairs component and component tasks are recordedin the task manager of the `model`. See also: [`ComponentTask`](@ref), [`TaskManager`](@ref). The `model` clock is [`set!`](@ref) and the files of [`Writer`](@ref) are openned.
"""
function initialize(model::Model)
    pairs = model.taskmanager.pairs
    components = getcomponents(model)
    for component in components
        pairs[component] = launch(component)
    end
    isrunning(model.clock) || set!(model.clock)  # Turnon clock internal generator.
    for writer in filter(block->isa(block, Writer), components)  # Open writer files.
        writer.file = jldopen(writer.file.path, "a")
    end
end

##### Model running
# Copy-paste loop body. See `run(model, withbar)`.
@def loopbody begin 
    put!(triggerport, fill(t, ncomponents))
    all(take!(handshakeport)) || @warn "Could not be approved"
    checktaskmanager(taskmanager)          
    applycallbacks(model)
end

"""
    run(model::Model, withbar::Bool=true)

Runs the `model` by triggering the components of the `model`. This triggering is done by generating clock tick using the model clock `model.clock`. Triggering starts with initial time of model clock, goes on with a step size of the sampling period of the model clock, and finishes at the finishing time of the model clock. If `withbar` is `true`, a progress bar indicating the simulation status is displayed on the console.

!!! warning 
    The `model` must first be initialized to be `run`. See also: [`initialize`](@ref).
```
"""
function run(model::Model, withbar::Bool=true)
    taskmanager = model.taskmanager
    triggerport, handshakeport = taskmanager.triggerport, taskmanager.handshakeport
    components = getcomponents(model)
    ncomponents = length(components)
    clock = model.clock
    withbar ? (@showprogress clock.dt for t in clock @loopbody end) : (for t in clock @loopbody end)
end

# ##### Model termination
# """ 
#     release(model::Model)

# Releaes the each component of `model`, i.e., the input and output bus of each component is released.
# """
# release(model::Model) = foreach(release, model.components)

"""
    terminate(model::Model)

Terminates `model` by terminating all the components of the `model`, i.e., the components tasks in the task manager of the `model` is terminated. See also: [`ComponentTask`](@ref), [`TaskManager`](@ref).
"""
function terminate(model::Model)
    taskmanager = model.taskmanager
    tasks = collect(values(taskmanager.pairs))
    any(istaskstarted.(tasks)) && put!(taskmanager.triggerport, fill(NaN, numcomponents(model)))
    isrunning(model.clock) && stop!(model.clock)
    return
end


function _simulate(sim::Simulation, reportsim::Bool, withbar::Bool)
    model = sim.model
    try
        @siminfo "Started simulation..."
        sim.state = :running

        @siminfo "Inspecting model..."
        inspect(model)
        @siminfo "Done."

        @siminfo "Initializing the model..."
        initialize(model)
        @siminfo "Done..."

        @siminfo "Running the simulation..."
        run(model, withbar)
        sim.state = :done
        sim.retcode = :success
        @siminfo "Done..."
        
        @siminfo "Terminating the simulation..."
        terminate(model)
        @siminfo "Done."
    catch e
        sim.state = :halted
        sim.retcode = :fail
        throw(e)
    end
    reportsim && report(sim)
    return sim
end

"""
    simulate(model::Model; simdir::String=tempdir(), simprefix::String="Simulation-", simname=string(uuid4()),
        logtofile::Bool=false, loglevel::LogLevel=Logging.Info, reportsim::Bool=false, withbar::Bool=true)

Simulates `model`. `simdir` is the path of the directory into which simulation files are saved. `simprefix` is the prefix of the simulation name `simname`. If `logtofile` is `true`, a log file for the simulation is constructed. `loglevel` determines the logging level. If `reportsim` is `true`, model components are saved into files. If `withbar` is `true`, a progress bar indicating the simualation status is displayed on the console.
"""
function simulate(model::Model; simdir::String=tempdir(), simprefix::String="Simulation-", simname=string(uuid4()),
    logtofile::Bool=false, loglevel::LogLevel=Logging.Info, reportsim::Bool=false, withbar::Bool=true)
    
    # Construct a Simulation
    sim = Simulation(model, simdir=simdir, simprefix=simprefix, simname=simname)
    sim.logger = logtofile ? SimpleLogger(open(joinpath(sim.path, "simlog.log"), "w+"), loglevel) : ConsoleLogger(stderr, loglevel)

    # Simualate the modoel
    with_logger(sim.logger) do
        _simulate(sim, reportsim, withbar)
    end
    logtofile && flush(sim.logger.stream)  # Close logger file stream.
    return sim
end

""" 
    simulate(model::Model, t0::Real, dt::Real, tf::Real; kwargs...)

Simulates the `model` starting from the initial time `t0` until the final time `tf` with the sampling interval of `tf`. For `kwargs` are 

* `logtofile::Bool`: If `true`, a log file is contructed logging each step of the simulation. 
* `reportsim::Bool`: If `true`, `model` components are written files after the simulation. When this file is read back, the model components can be consructed back with their status at the end of the simulation.
* `simdir::String`: The path of the directory in which simulation file are recorded. 
"""
function simulate(model::Model, t0::Real, dt::Real, tf::Real; kwargs...)
    set!(model.clock, t0, dt, tf)
    simulate(model; kwargs...)
end


# """ 
#     findin(model::Model, id::UUID)

# Returns the component of the `model` corresponding whose id is `id`.

#     findin(model::Model, comp::AbstractComponent)

# Returns the compeonent whose variable name is `comp`.
# """
# function findin end
# findin(model::Model, id::UUID) = model.components[findfirst(block -> block.id == id, model.components)]
# findin(model::Model, comp::AbstractComponent) = model.components[findfirst(block -> block.id == comp.id, model.components)]
