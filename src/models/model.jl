# This file includes the Model object
import Base: getindex, setindex!, push!

"""
    Node(component, idx, label)

Constructs a model `Node` with `component`. `idx` is the index and `label` is label of `Node`.
"""
struct Node{CP, L}
    component::CP 
    idx::Int    
    label::L 
end

show(io::IO, node::Node) = print(io, "Node(component:$(node.component), idx:$(node.idx), label:$(node.label))")

""" 
    Branch(nodepair, indexpair, links)

Constructs a `Branch` connecting the first and second element of `nodepair` with `links`. `indexpair` determines the subindices by which the elements of `nodepair` are connected.
"""
struct Branch{NP, IP, LN}
    nodepair::NP 
    indexpair::IP 
    links::LN
end

show(io::IO, branch::Branch) = print(io, "Branch(nodepair:$(branch.nodepair), indexpair:$(branch.indexpair), ",
    "links:$(branch.links))")

"""
    Model(components::AbstractVector)

Constructs a `Model` whose with components `components` which are of type `AbstractComponent`.

    Model()

Constructs a `Model` with empty components. After the construction, components can be added to `Model`.

!!! warning
    `Model`s are units that can be simulated. As the data flows through the branches i.e. input output busses of the components, its is important that the components must be connected to each other. See also: [`simulate`](@ref)
"""
struct Model{GR, ND, BR, CK, TM, CB}
    graph::GR
    nodes::ND
    branches::BR 
    clock::CK
    taskmanager::TM
    callbacks::CB
    name::Symbol
    id::UUID
    function Model(nodes::AbstractVector=[], branches::AbstractVector=[]; 
        clock=Clock(0, 0.01, 1.), callbacks=nothing, name=Symbol())
        graph = SimpleDiGraph()
        taskmanager = TaskManager()
        new{typeof(graph), typeof(nodes), typeof(branches), typeof(clock), typeof(taskmanager),
            typeof(callbacks)}(graph, nodes, branches, clock, taskmanager, callbacks, name, uuid4())
    end
end

show(io::IO, model::Model) = print(io, "Model(numnodes:$(length(model.nodes)), ",
    "numedges:$(length(model.branches)), timesettings=($(model.clock.t), $(model.clock.dt), $(model.clock.tf)))")


##### Addinng nodes and branches.
"""
    addnode(model, component; label=nothing)

Adds a node to `model`. Component is `component` and `label` is `label` the label of node. Returns added node.

# Example 
```jldoctest 
julia> model = Model()
Model(numnodes:0, numedges:0, timesettings=(0.0, 0.01, 1.0))

julia> addnode(model, SinewaveGenerator(), label=:gen)
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)
```
"""
function addnode(model::Model, component::AbstractComponent; label=nothing)
    label === nothing || label in [node.label for node in model.nodes] && error(label," is already assigned.")
    node = Node(component, length(model.nodes) + 1, label)
    push!(model.nodes, node)
    register(model.taskmanager, component)
    add_vertex!(model.graph)
    node
end

"""
    getnode(model, idx::Int) 

Returns node of `model` whose index is `idx`.

    getnode(model, label)

Returns node of `model` whose label is `label`.

# Example
```jldoctest
julia> model = Model()
Model(numnodes:0, numedges:0, timesettings=(0.0, 0.01, 1.0))

julia> addnode(model, SinewaveGenerator(), label=:gen)
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)

julia> addnode(model, Gain(), label=:gain)
Node(component:Gain(gain:1.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64})), idx:2, label:gain)

julia> getnode(model, :gen)
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)

julia> getnode(model, 2)
Node(component:Gain(gain:1.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64})), idx:2, label:gain)
```
"""
getnode(model::Model, idx::Int) = model.nodes[idx]
getnode(model::Model, label) = filter(node -> node.label === label, model.nodes)[1]

function register(taskmanager, component)
    triggerport, handshakeport = taskmanager.triggerport, taskmanager.handshakeport
    triggerpin, handshakepin = Outpin(), Inpin{Bool}()
    connect(triggerpin, component.trigger)
    connect(component.handshake, handshakepin)
    push!(triggerport.pins, triggerpin)
    push!(handshakeport.pins, handshakepin)
    taskmanager.pairs[component] = nothing
end

"""
    addbranch(model::Model, branch::Branch)

Adds `branch` to branched of `model`.
"""
function addbranch(model::Model, nodepair::Pair, indexpair::Pair=(:)=>(:))
    srcnode, dstnode = getnode(model, nodepair.first), getnode(model, nodepair.second)
    links = connect(srcnode.component.output[indexpair.first], dstnode.component.input[indexpair.second])
    srcidx, dstidx = srcnode.idx, dstnode.idx
    branch =  Branch(srcidx => dstidx, indexpair, links)
    push!(model.branches, branch)
    add_edge!(model.graph, srcidx, dstidx)
    branch
end

getbranch(model::Model, nodepair::Pair{Int, Int}) = filter(branch -> branch.nodepair == nodepair, model.branches)[1]
getbranch(model::Model, nodepair::Pair{Symbol, Symbol}) = 
    getbranch(model, getnode(model, nodepair.first).idx => getnode(model, nodepair.second).idx)

"""
    deletebranch(model::Model, branch::Branch)

Deletes `branch` from branched of `model`.

    deletebranch(model::Model, srcnode::Node, dstnode::Node) 

Deletes branch between `srcnode` and `dstnode` of the `model`.
"""
function deletebranch(model::Model, nodepair::Pair{Int, Int})
    srcnode, dstnode = getnode(model, nodepair.first), getnode(model, nodepair.second)
    branch = getbranch(model, nodepair)
    srcidx, dstidx = branch.indexpair
    disconnect(srcnode.component.output[srcidx], dstnode.component.input[dstidx])
    deleteat!(model.branches, findall(br -> br == branch, model.branches))
    rem_edge!(model.graph, srcnode.idx, dstnode.idx)
    branch
end
deletebranch(model::Model, nodepair::Pair{Symbol, Symbol}) = 
    deletebranch(model, getnode(model, nodepair.first).idx, getnode(model, nodepair.second).idx)


##### Model inspection.
"""
    inspect(model::Model)

Inspects the `model`. If `model` has some inconsistencies such as including algebraic loops or unterminated busses and 
error is thrown.
"""
function inspect(model, breakpoints::Vector{Int}=Int[])
    loops = getloops(model)
    if !isempty(loops)
        msg = "\tThe model has algrebraic loops:$(loops)"
        msg *= "\n\t\tTrying to break these loops..."
        @info msg
        while !isempty(loops)
            loop = popfirst!(loops)
            breakpoint = isempty(breakpoints) ? length(loop) : popfirst!(breakpoints)
            breakloop(model, loop, breakpoint)
            @info "\tLoop $loop is broken"
            loops = getloops(model)
        end
    end
end


"""
    getloops(model)

Returns idx of nodes that constructs algrebraic loops.
"""
getloops(model::Model) = simplecycles(model.graph)

"""
    breakloop(model, loop, breakpoint=length(loop))

Breaks the algebraic `loop` of `model`. The `loop` of the `model` is broken by inserting a `Memory` at the `breakpoint` 
of loop.
"""
function breakloop(model::Model, loop, breakpoint=length(loop)) 
    nftidx = findfirst(idx -> !isfeedthrough(getnode(model, idx).component), loop)
    nftidx === nothing || (breakpoint = nftidx)

    # Delete the branch at the breakpoint.
    srcnode = getnode(model, loop[breakpoint])
    if breakpoint == length(loop)
        dstnode = getnode(model, loop[1])
    else 
        dstnode = getnode(model, loop[(breakpoint + 1)])
    end
    branch = getbranch(model, srcnode.idx => dstnode.idx)
    
    # Construct the loopbreaker.
    if nftidx === nothing
        nodefuncs = wrap(model, loop)
        ff = feedforward(nodefuncs, breakpoint)
        n = length(srcnode.component.output)
        breaker = StaticSystem((u,t) -> findroot(ff, n, t), nothing, Outport(n))
    else 
        component = srcnode.component
        n = length(component.output) 
        breaker = StaticSystem((u,t) -> component.outputfunc(component.state, nothing, t), nothing, Outport(n))
    end
    # newidx = length(model.nodes) + 1 
    newnode = addnode(model, breaker)
    
    # Delete the branch at the breakpoint
    deletebranch(model, branch.nodepair)
    
    # Connect the loopbreker to the loop at the breakpoint.
    addbranch(model, newnode.idx => dstnode.idx, branch.indexpair)
    return newnode
end

function wrap(model, loop)
    graph = model.graph
    map(loop) do idx 
        node = getnode(model, idx)
        innbrs = filter(i -> i ∉ loop, inneighbors(graph, idx))
        outnbrs = filter(i -> i ∉ loop, outneighbors(graph, idx))
        if isempty(innbrs) && isempty(outnbrs)
            zero_in_zero_out(node)
        elseif isempty(innbrs) && !isempty(outnbrs)
            zero_in_nonzero_out(node, getoutmask(model, node, loop))
        elseif !isempty(innbrs) && isempty(outnbrs)
            nonzero_in_zero_out(node, getinmask(model, node, loop))
        else 
            nonzero_in_nonzero_out(node, getinmask(model, node, loop), getoutmask(model, node, loop))
        end 
    end
end

function zero_in_zero_out(node) 
    component = node.component
    function func(ut)
        u, t = ut 
        out = [_computeoutput(component, u, t)...]
        out, t
    end
end

function zero_in_nonzero_out(node, outmask)
    component = node.component
    function func(ut)
        u, t = ut 
        out = [_computeoutput(component, u, t)...]
        out[outmask], t
    end
end

function nonzero_in_zero_out(node, inmask) 
    component = node.component
    nin = length(inmask)
    function func(ut)
        u, t = ut 
        uu = zeros(nin)
        uu[inmask] .= readbuffer(component.input, inmask)
        uu[.!inmask] .= u
        out = [_computeoutput(component, uu, t)...]
        out, t
    end
end

function nonzero_in_nonzero_out(node, inmask, outmask)
    component = node.component
    nin = length(inmask)
    function func(ut)
        u, t = ut 
        uu = zeros(nin)
        uu[inmask] .= readbuffer(component.input, inmask)
        uu[.!inmask] .= u
        out = [_computeoutput(component, uu, t)...]
        out[outmask]
        out, t
    end
end

function getinmask(model, node, loop)
    idx = node.idx
    inmask = falses(length(node.component.input))
    for nidx in filter(n -> n ∉ loop, inneighbors(model.graph, idx)) # Not-in-loop inneighbors
        k = getbranch(model, nidx => idx).indexpair.second
        if length(k) == 1 
            inmask[k] = true
        else
            inmask[k] .= trues(length(k))
        end
    end
    inmask
end

function getoutmask(model, node, loop)
    idx = node.idx
    outmask = falses(length(node.component.output))
    for nidx in filter(n -> n ∈ loop, outneighbors(model.graph, idx)) # In-loop outneighbors
        k = getbranch(model, idx => nidx).indexpair.first
        if length(k) == 1 
            outmask[k] = true
        else 
            outmask[k] .= trues(length(k))
        end
    end
    outmask
end

readbuffer(input, inmask) = map(pin -> read(pin.link.buffer), input[inmask])
_computeoutput(comp::AbstractStaticSystem, u, t) = comp.outputfunc(u, t)
_computeoutput(comp::AbstractDynamicSystem, u, t) = comp.outputfunc(comp.state, map(uu -> t -> uu, u), t)

function feedforward(nodefuncs, breakpoint=length(nodefuncs))
    (u, t) -> ∘(reverse(circshift(nodefuncs, -breakpoint))...)((u, t))[1] - u
end

function findroot(ff, n, t)
    sol = nlsolve((dx, x) -> (dx .= ff(x, t)), rand(n))
    sol.zero
end

function isfeedthrough(component)
    try 
        out = typeof(component) <: AbstractStaticSystem ? 
            component.outputfunc(nothing, 0.) : component.outputfunc(component.state, nothing, 0.)
        return false
    catch ex 
        return true 
    end
end

##### Model initialization
"""
    initialize(model::Model)

Initializes `model` by launching component task for each of the component of `model`. The pairs component and component tasks are recordedin the task manager of the `model`. The `model` clock is [`set!`](@ref) and the files of [`Writer`](@ref) are openned.
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

Terminates `model` by terminating all the components of the `model`, i.e., the components tasks in the task manager of the `model` is terminated.
"""
function terminate(model::Model)
    taskmanager = model.taskmanager
    tasks = unwrap(collect(values(taskmanager.pairs)), Task, depth=length(taskmanager.pairs))
    any(istaskstarted.(tasks)) && put!(taskmanager.triggerport, fill(NaN, length(model.nodes)))
    isrunning(model.clock) && stop!(model.clock)
    return
end


function _simulate(sim::Simulation, reportsim::Bool, withbar::Bool, breakpoints::Vector{Int})
    model = sim.model
    @siminfo "Started simulation..."
    sim.state = :running

    @siminfo "Inspecting model..."
    inspect(model, breakpoints)
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

    reportsim && report(sim)
    return sim
end

"""
    simulate(model::Model; simdir::String=tempdir(), simprefix::String="Simulation-", simname=string(uuid4()),
        logtofile::Bool=false, loglevel::LogLevel=Logging.Info, reportsim::Bool=false, withbar::Bool=true)

Simulates `model`. `simdir` is the path of the directory into which simulation files are saved. `simprefix` is the prefix of the simulation name `simname`. If `logtofile` is `true`, a log file for the simulation is constructed. `loglevel` determines the logging level. If `reportsim` is `true`, model components are saved into files. If `withbar` is `true`, a progress bar indicating the simualation status is displayed on the console.
"""
function simulate(model::Model; simdir::String=tempdir(), simprefix::String="Simulation-", simname=string(uuid4()),
    logtofile::Bool=false, loglevel::LogLevel=Logging.Info, reportsim::Bool=false, withbar::Bool=true, 
    breakpoints::Vector{Int}=Int[])
    
    # Construct a Simulation
    sim = Simulation(model, simdir=simdir, simprefix=simprefix, simname=simname)
    sim.logger = logtofile ? SimpleLogger(open(joinpath(sim.path, "simlog.log"), "w+"), loglevel) : ConsoleLogger(stderr, loglevel)

    # Simualate the modoel
    with_logger(sim.logger) do
        _simulate(sim, reportsim, withbar, breakpoints)
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

##### Plotting model
"""
    signalflow(model, args...; kwargs...)

Plots the signal flow of `model`. `args` and `kwargs` are passed into [`gplot`](https://github.com/JuliaGraphs/GraphPlot.jl) function.
"""
signalflow(model::Model, args...; kwargs...) = 
    gplot(model.graph, args...; nodelabel=[node.label for node in model.nodes], kwargs...)
