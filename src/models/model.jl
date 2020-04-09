# This file includes the Model object
import Base: getindex
import LightGraphs: SimpleDiGraph, add_edge!, add_vertex!, simplecycles

mutable struct Node{CP}
    component::CP 
    idx::Int 
    label::Symbol 
end 

mutable struct Edge{SI<:AbstractVector{<:Int}, DI<:AbstractVector{<:Int}, LN<:AbstractVector{<:Link}}
    src::Int  
    dst::Int  
    srcidx::SI
    dstidx::DI
    links::LN
end
function Edge(src, dst, srcidx, dstidx, links)
    srcidx = [srcidx...]
    dstidx = [dstidx...]
    Edge{typeof(srcidx), typeof(dstidx), typeof(links)}(src, dst, srcidx, dstidx, links)
end
function Edge(src, dst, srcidx, dstidx)
    n = length(srcidx)
    n == length(dstidx) || error("srcidx and dstidx must have same length.")
    links = [Link() for i = 1 : n]
    Edge(src, dst, srcidx, dstidx, links)
end

"""
    Model(components::AbstractVector)

Constructs a `Model` whose with components `components` which are of type `AbstractComponent`.

    Model()

Constructs a `Model` with empty components. After the construction, components can be added to `Model`.

!!! warning
    `Model`s are units that can be simulated. As the data flows through the edges i.e. input output busses of the components, its is important that the components must be connected to each other. See also: [`simulate`](@ref)
"""
mutable struct Model{GR, ND, ED, CK, TM, CB}
    graph::GR
    nodes::ND
    edges::ED 
    clock::CK
    taskmanager::TM
    callbacks::CB
    name::Symbol
    id::UUID
    function Model(nodes::AbstractVector=[], edges::AbstractVector=[]; 
        clock=Clock(0, 0.01, 1.), callbacks=nothing, name=Symbol())
        graph = SimpleDiGraph()
        taskmanager = TaskManager()
        model = new{typeof(graph), typeof(nodes), typeof(edges), typeof(clock), typeof(taskmanager),
            typeof(callbacks)}(graph, nodes, edges, clock, taskmanager, callbacks, name, uuid4())
        foreach(node -> addnode(model, node), nodes)
        foreach(edge -> edges(model, edge), edges)
        model
    end
end

show(io::IO, model::Model) = print(io, "Model(numnodes:$(length(model.nodes)), ",
    "numedges:$(length(model.edges)), timesettings=($(model.clock.t), $(model.clock.dt), $(model.clock.tf)))")

gplot(model::Model) = gplot(model.graph, nodelabel=map(i -> getname(model, i),  vertices(model.graph)))

function getindex(model::Model, idx::Int) 
    nodes = filter(node -> node.idx == idx, model.nodes)
    length(nodes) == 1 ? nodes[1] : error("Multiple index")
end
function getindex(model::Model, label::Symbol) 
    nodes = filter(node -> node.label == label, model.nodes)
    length(nodes) == 1 ? nodes[1] : error("Multiple labels")
end
function getindex(model::Model, src::Int, dst::Int) 
    edges = filter(edge -> edge.src==src && edge.dst == dst, model.edges)
    length(edges) == 1 ? edges[1] : error("Multiple indexes")
end
function getindex(model::Model, src::Symbol, dst::Symbol) 
    model[model[src].idx, model[dst].idx]
end

##### Accessing model components or edges
# getindex(model::Model, name::Symbol) = model.graph[name, :name]
# getname(model, idx::Int) = getfield(getcomponent(model, idx), :name)
# getcomponent(model::Model, name::Symbol) = get_prop(model.graph, model[name], :component)
# getcomponent(model::Model, idx::Int) = get_prop(model.graph, idx, :component)
# getcomponents(model) = map(idx -> getcomponent(model, idx), vertices(model.graph))
# getconnection(model::Model, srcidx::Int, dstidx::Int, prop=:connection) = get_prop(model.graph, srcidx, dstidx, prop)
# getconnection(model::Model, srcname::Symbol, dstname::Symbol, prop=:connection) = 
#     get_prop(model.graph, model[srcname], model[dstname], prop)


# function addcomponent(model::Model, components::AbstractComponent...)
#     taskmanager = model.taskmanager
#     graph = model.graph 
#     n = nv(graph)
#     for (k, component) in enumerate(components)
#         add_vertex!(graph, :component, component)
#         set_indexing_prop!(graph, n + k, :name, component.name)
#         register(taskmanager, component) 
#     end 
# end

# function addedge(model::Model, srcname, dstname, srcidx=nothing, dstidx=nothing)
#     src, dst = model[srcname], model[dstname]
#     srccomp, dstcomp = getcomponent(model, src), getcomponent(model, dst)
#     outport = srccomp.output
#     inport = dstcomp.input
#     srcidx === nothing && (srcidx = 1 : length(outport))
#     dstidx === nothing && (dstidx = 1 : length(inport))
#     connection = connect(outport[srcidx], inport[dstidx])
#     add_edge!(model.graph, src, dst, Dict(:connection => connection, :srcidx => srcidx, :dstidx => dstidx))
# end

##### Modifying models
function addnode(model::Model, node::Node)
    push!(model.nodes, node)
    register(model.taskmanager, node.component)
    add_vertex!(model.graph)
end

function addnode(model::Model, component::AbstractComponent; label::Symbol=Symbol()) 
    n = length(model.nodes) + 1
    addnode(model, Node(component, n, label))
end


function addedge(model::Model, edge::Edge)
    push!(model.edges, edge)
    add_edge!(model.graph, edge.src, edge.dst)
end

function addedge(model::Model, src::Node, dst::Node, srcidx=nothing, dstidx=nothing) 
    srcidx = srcidx === nothing ? (srcidx = 1 : length(src.component.output)) : [srcidx...]
    dstidx = dstidx === nothing ? (dstidx = 1 : length(dst.component.input)) : [dstidx...]
    links = connect(src.component.output[srcidx], dst.component.input[dstidx])
    addedge(model, Edge(src.idx, dst.idx, srcidx, dstidx, links))
end

addedge(model::Model, src, dst, srcidx=nothing, dstidx=nothing) = addedge(model, model[src], model[dst], srcidx, dstidx)

function register(taskmanager, component)
    triggerport, handshakeport = taskmanager.triggerport, taskmanager.handshakeport
    triggerpin, handshakepin = Outpin(), Inpin{Bool}()
    connect(triggerpin, component.trigger)
    connect(component.handshake, handshakepin)
    push!(triggerport.pins, triggerpin)
    push!(handshakeport.pins, handshakepin)
    taskmanager.pairs[component] = nothing
end

##### Model inspection.
"""
    inspect(model::Model)

Inspects the `model`. If `model` has some inconsistencies such as including algebraic loops or unterminated busses and error is thrown.
"""
function inspect(model)
    if hasloops(model)
        loops = getloops(model)
        components = map(loop -> map(idx -> model[idx].component, loop), loops)
        msg = "Simulation aborted. The model has algrebraic loops: $components"
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


getloops(model::Model) = simplecycles(model.graph)

hasmemory(model, loop) = any(isa.(map(idx -> model[idx].component, loop), AbstractMemory))

function hasloops(model::Model)
    loops = getloops(model)
    isempty(loops) && return false
    return any(map(loop -> !hasmemory(model, loop), loops))
end

function breakloop(model::Model, loop, breakpoint=length(loop)) 
    nodefuncs = loopnodefuncs(model, loop)
    ff = feedforward(nodefuncs, breakpoint)
    funcs = [u -> ff(u)[i] for i in 1 : length(ff)]
    x0 = map(fi -> find_zero(fi, rand()), funcs)
    memory = Memory(Inport(length(x0), initial=x0))
    srcnode = model[breakpoint].component 
    dstnode = model[(breakpoint + 1) % length(loop)].component 
    disconnect(srcnode.output, dstnode.input)
    addnode(model, memory)
    addedge(model, srcnode.idx, model.nodes[end].idx)
    addedge(model, model.node[end].idx, dstnode.idx)
end

function wrap(component::AbstractDynamicSystem, inval, inidxs, outidxs)
    nin = length(component.input)
    outputfunc = component.outputfunc
    x = component.state 
    function gf(u)
        uu = zeros(nin) 
        uu[inidxs] .= inval 
        uu[filter(i -> i ∉ inidxs, 1 : nin)] .= u
        out = outputfunc(x, uu, 0.)
        out[outidxs]
    end
end

function wrap(component::AbstractSource, inval, inidxs, outidxs)
    nin = length(component.input)
    outputfunc = component.outputfunc
    function gf(u)
        uu = zeros(nin) 
        uu[inidxs] .= inval 
        uu[filter(i -> i ∉ inidxs, 1 : nin)] .= u
        out = outputfunc(uu, 0.)
        typeof(out) <: Real ? [out] : out
    end
end


function neighborsinside(loop, innbrs, outnbrs)
    isempty(filter(v -> v ∉ loop, innbrs)) && isempty(filter(v -> v ∉ loop, outnbrs))
end


function loopnodefuncs(model, loop)
    graph = model.graph
    nodefuncs = Vector{Function}(undef, length(loop))
    for (k, idx) in enumerate(loop)
        loopcomponent = model[idx].component
        innbrs, outnbrs = inneighbors(graph, idx), outneighbors(graph, idx)
        if neighborsinside(loop, innbrs, outnbrs)
            nodefunc = loopcomponent.outputfunc
        else 
            nodeinvals = Float64[]
            nodeinidxs = Int[]
            for innbr in filter(idx -> idx ∉ loop, innbrs)
                inedge = model[innbr,idx]
                innbrcomponent = model[innbr].component
                if innbrcomponent isa AbstractSource
                    nodeinval = [innbrcomponent.outputfunc(0.)...][inedge.srcidx]
                elseif innbrcomponent isa AbstractDynamicSystem 
                    out  = innbrcomponent.input === nothing ? 
                        innbrcomponent.outputfunc(nothing, innbrcomponent.state, 0.) : error("One step further")
                    nodeinval = out[inedge.srcidx...]
                else 
                    error("One step futher")
                end
                append!(nodeinvals, nodeinval)
                append!(nodeinidxs, inedge.dstidx)
            end
            outnbr = filter(idx -> idx ∈ loop, outnbrs)[1]
            outedge = model[idx, outnbr]
            nodefunc = wrap(loopcomponent, nodeinvals, nodeinidxs, outedge.srcidx)    
        end
        nodefuncs[k] = nodefunc
    end
    nodefuncs
end

feedforward(nodefuncs, breakpoint=length(nodefuncs)) = x -> ∘(circshift(nodefuncs, -breakpoint)...) - x

##### Model initialization
"""
    initialize(model::Model)

Initializes `model` by launching component task for each of the component of `model`. The pairs component and component tasks are recordedin the task manager of the `model`. See also: [`ComponentTask`](@ref), [`TaskManager`](@ref). The `model` clock is [`set!`](@ref) and the files of [`Writer`](@ref) are openned.
"""
function initialize(model::Model)
    pairs = model.taskmanager.pairs
    nodes = model.nodes
    for node in nodes
        component = node.component
        pairs[component] = launch(component)
    end
    isrunning(model.clock) || set!(model.clock)  # Turnon clock internal generator.
    for node in filter(node->isa(node.component, Writer), model.nodes)
        node.component.file = jldopen(node.component.file.path, "a")
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
    ncomponents = length(model.nodes)
    clock = model.clock
    withbar ? (@showprogress clock.dt for t in clock @loopbody end) : (for t in clock @loopbody end)
end

# ##### Model termination
# """ 
#     release(model::Model)

# Releaes the each component of `model`, i.e., the input and output bus of each component is released.
# """
# release(model::Model) = foreach(release, model.nodes)

"""
    terminate(model::Model)

Terminates `model` by terminating all the components of the `model`, i.e., the components tasks in the task manager of the `model` is terminated. See also: [`ComponentTask`](@ref), [`TaskManager`](@ref).
"""
function terminate(model::Model)
    taskmanager = model.taskmanager
    tasks = unwrap(collect(values(taskmanager.pairs)), Task, depth=length(taskmanager.pairs))
    any(istaskstarted.(tasks)) && put!(taskmanager.triggerport, fill(NaN, length(model.nodes)))
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
# findin(model::Model, id::UUID) = model.nodes[findfirst(block -> block.id == id, model.nodes)]
# findin(model::Model, comp::AbstractComponent) = model.nodes[findfirst(block -> block.id == comp.id, model.nodes)]
