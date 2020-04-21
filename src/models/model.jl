# This file includes the Model object
import Base: getindex, setindex!, push!

"""
    Node(component, idx, label)

Constructs a model `Node` with `component`. `idx` is the index and `label` is label of `Node`.
"""
struct Node{CP}
    component::CP 
    idx::Int    
    label::Symbol 
end 

show(io::IO, node::Node) = print(io, "Node(component:$(node.component), idx:$(node.idx), label:$(node.label))")


"""
    Indices(pair)

Constructs an a branch `Indices` with `pair`. `pair` determines the subindices of the port of node components of a model.
"""
struct Indices{P<:Pair} 
    pair::P 
end 
Indices() = Indices((:) => (:))

show(io::IO, edge::Indices) = print(io, "Indices($(edge.pair))")

""" 
    Branch(nodepair, edgepair, links)

Constructs a `Branch` connecting the first and second element of `nodepair` with `links`. `edgepair` determines the subindices by which the elements of `nodepair` are connected.
"""
struct Branch{NP, EP, LN}
    nodepair::NP 
    edgepair::EP 
    links::LN
end

show(io::IO, branch::Branch) = print(io, "Branch(nodepair:$(branch.nodepair), edgepair:$(branch.edgepair), ",
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
        model = new{typeof(graph), typeof(nodes), typeof(branches), typeof(clock), typeof(taskmanager),
            typeof(callbacks)}(graph, nodes, branches, clock, taskmanager, callbacks, name, uuid4())
        foreach(node -> addnode(model, node), nodes)
        foreach(edge -> branches(model, edge), branches)
        model
    end
end

show(io::IO, model::Model) = print(io, "Model(numnodes:$(length(model.nodes)), ",
    "numedges:$(length(model.branches)), timesettings=($(model.clock.t), $(model.clock.dt), $(model.clock.tf)))")


##### Addinng nodes and branches.
"""
    addnode(model::Model, node::Node)

Add `node` to nodes of `model`.
"""
function addnode(model::Model, node::Node)
    checklabel(model, node)
    push!(model.nodes, node)
    register(model.taskmanager, node.component)
    add_vertex!(model.graph)
end

checklabel(model,node) = node.label in [node.label for node in model.nodes] && error(node.label," is already assigned.")

"""
    addbranch(model::Model, branch::Branch)

Adds `branch` to branched of `model`.
"""
function addbranch(model::Model, branch::Branch)
    push!(model.branches, branch)
    add_edge!(model.graph, branch.nodepair.first, branch.nodepair.second)
end

"""
    deletebranch(model::Model, branch::Branch)

Deletes `branch` from branched of `model`.

    deletebranch(model::Model, srcnode::Node, dstnode::Node) 

Deletes branch between `srcnode` and `dstnode` of the `model`.
"""
function deletebranch(model::Model, branch::Branch)
    nodepair = branch.nodepair
    srcnode, dstnode = model[nodepair.first], model[nodepair.second]
    srcidx, dstidx = branch.edgepair.pair
    disconnect(srcnode.component.output[srcidx], dstnode.component.input[dstidx]) 
    rem_edge!(model.graph, srcnode.idx, dstnode.idx)
end
deletebranch(model::Model, srcnode::Node, dstnode::Node) = deletebranch(model, model[srcnode.idx => dstnode.idx])

"""
    setindex!(model, component, idx)

Adds a node to `model` whose component is `component` and index is `idx`. `idx` can be of type `Int` or `Symbol`. The 
syntax `model[idx] = component` is equal to `setindex!(model, component, idx)`. 

# Example 
```julia
julia> model[1] = SinewaveGenerator() 
SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0)

julia> model[:adder] = Adder(Inport(2))
Adder(signs:(+, +), input:Inport(numpins:2, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64}))
```
"""
setindex!(model::Model, component::AbstractComponent, idx::Int) = addnode(model, Node(component, idx, Symbol(uuid4())))
setindex!(model::Model, component::AbstractComponent, label::Symbol) = 
    addnode(model, Node(component, length(model.nodes) + 1, label))

"""
    setindex!(model, edgepair, nodepair)

Adds a branch to `model` that connects the element of `nodepair` with subindices `edgepair`. The syntax 
`model[nodepair] = edgepair` is equal to `setindex!(model, edgepair, nodepair)`.

# Example 
```jldoctest 
julia> model = Model();

julia> model[:gen] = SinewaveGenerator();

julia> model[:gain] = Gain(Inport());

julia> model[:gen => :gain] = Indices();

julia> isconnected(model[:gen].component.output, model[:gain].component.input)
true
```
"""
function setindex!(model::Model, edgepair::Indices, nodepair::Pair{Int, Int}) 
    src, dst = model[nodepair.first].component, model[nodepair.second].component
    links = connect(src.output[edgepair.pair.first], dst.input[edgepair.pair.second])
    addbranch(model, Branch(nodepair, edgepair, links))
end
function setindex!(model::Model, edgepair::Indices, nodepair::Pair{Symbol, Symbol}) 
    src, dst = model[nodepair.first], model[nodepair.second]
    setindex!(model, edgepair, src.idx => dst.idx)
end


"""
    getindex(model, idx) 

Returns the node of whose index is `idx`. The syntax `model[idx]` equals to `getindex(model, idx)`.

# Example 
```jldoctest
julia> model = Model();

julia> model[:gen] = SinewaveGenerator();

julia> model[:gain] = Gain(Inport());

julia> model[1]
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)

julia> model[:gen]
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)

julia> model[:gain]
Node(component:Gain(gain:1.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64})), idx:2, label:gain)

julia> model[2] 
Node(component:Gain(gain:1.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64})), idx:2, label:gain)
```
"""
function getindex(model::Model, idx::Int) 
    nodes = filter(node -> node.idx == idx, model.nodes)
    checklengh(length(nodes))
    nodes[1]
end
function getindex(model::Model, label::Symbol) 
    nodes = filter(node -> node.label == label, model.nodes)
    checklengh(length(nodes))
    nodes[1]
end


"""
    getindex(model, nodepair)

Returns `model` branch between `nodepair`. The syntax `model[nodepair]` is equal to `getindex(model, nodepair)`.

# Example 
```jldoctest
julia> model = Model(); 

julia> model[:gen] = SinewaveGenerator(); 

julia> model[:gain] = Gain(Inport());

julia> model[:gen => :gain] = Indices();

julia> model[:gen => :gain]
Branch(nodepair:1 => 2, edgepair:Indices(Colon() => Colon()), links=Link{Float64}[Link(state:open, eltype:Float64, isreadable:false, iswritable:false)])
```
"""
function getindex(model::Model, nodepair::Pair{Int, Int}) 
    branches = filter(branch -> branch.nodepair == nodepair, model.branches)
    checklengh(length(branches))
    branches[1]
end
function getindex(model::Model, nodepair::Pair{Symbol, Symbol}) 
    getindex(model, model[nodepair.first].idx => model[nodepair.second].idx)
end

function checklengh(n)
    n == 0 &&  error("Node cannot be found")
    n > 1 &&  error("Multiple nodes found.")
end

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

Inspects the `model`. If `model` has some inconsistencies such as including algebraic loops or unterminated busses and 
error is thrown.
"""
function inspect(model)
    loops = getloops(model)
    if !isempty(loops)
        msg = "\tThe model has algrebraic loops:$(loops)"
        msg *= "\n\t\tTrying to break these loops..."
        @info msg
        while !isempty(loops)
            loop = pop!(loops)
            # try 
                breakloop(model, loop)
            # catch ex
            #     error(ex, " Algebric loop:$loop could not be broken.")
            # end
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
    # Delete the branch at the breakpoint.
    srcnode = model[loop[breakpoint]]
    dstnode = model[loop[(breakpoint + 1) % length(loop)]]
    branch = model[srcnode.idx => dstnode.idx]
    
    # Construct the loopbreaker.
    nodefuncs = wrap(model, loop)
    ff = feedforward(nodefuncs, breakpoint)
    n = length(srcnode.component.output)
    breaker = StaticSystem((u,t) -> findroot(ff, n, t), nothing, Outport(n))
    newidx = length(model.nodes) + 1 
    model[newidx] = breaker
    
    # Delete the branch at the breakpoint
    deletebranch(model, branch)
    
    # Connect the loopbreker to the loop at the breakpoint.
    srcidx, dstidx = branch.edgepair.pair
    model[newidx => dstnode.idx] = Indices(srcidx => dstidx)
    return true 
end

function wrap(model, loop)
    graph = model.graph
    map(loop) do idx 
        node = model[idx]
        innbrs, outnbrs = inneighbors(graph, idx), outneighbors(graph, idx)
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
        out = [computeout(component, u, t)...]
        out, t
    end
end

function zero_in_nonzero_out(node, outmask)
    component = node.component
    function func(ut)
        u, t = ut 
        out = [computeout(component, u, t)...]
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
        out = [computeout(component, uu, t)...]
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
        out = [computeout(component, uu, t)...]
        out[outmask]
        out, t
    end
end

function getinmask(model, node, loop)
    idx = node.idx
    inmask = falses(length(node.component.input))
    for nidx in filter(n -> n ∉ loop, inneighbors(model.graph, idx)) # Not-in-loop inneighbors
        k = model[nidx => idx].edgepair.pair.second
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
        k = model[idx => nidx].edgepair.pair.first
        if length(k) == 1 
            outmask[k] = true
        else 
            outmask[k] .= trues(length(k))
        end
    end
    outmask
end

readbuffer(input, inmask) = map(pin -> read(pin.link.buffer), input[inmask])
computeout(comp::AbstractStaticSystem, u, t) = comp.outputfunc(u, t)
computeout(comp::AbstractDynamicSystem, u, t) = comp.outputfunc(comp.state, map(v -> (t -> v), u), t)

function feedforward(nodefuncs, breakpoint=length(nodefuncs))
    (u, t) -> ∘(reverse(circshift(nodefuncs, -breakpoint))...)((u, t))[1] - u
end

function findroot(ff, n, t)
    sol = nlsolve((dx, x) -> (dx .= ff(x, t)), zeros(n))
    sol.zero
end

# hasmemory(model, loop) = any(isa.(map(idx -> model[idx].component, loop), AbstractMemory))

# """
#     hasloops(model)

# Return `true` is `model` has algrebraic loops.
# """
# function hasloops(model::Model)
#     loops = getloops(model)
#     isempty(loops) && return false
#     return any(map(loop -> !hasmemory(model, loop), loops))
# end

# #
# # `wrap` function wraps component output function with inval to construct loop node input-output function.
# #
# function wrap(component::AbstractDynamicSystem, inval, inidxs, outidxs)
#     nin = length(component.input)
#     outputfunc = component.outputfunc
#     x = component.state 
#     function gf(ut)
#         u, t = ut
#         uu = zeros(nin) 
#         uu[inidxs] .= map(f -> f(t), inval) 
#         uu[filter(i -> i ∉ inidxs, 1 : nin)] .= u
#         out = outputfunc(x, uu, t)
#         (out[outidxs], t)
#     end
# end

# function wrap(component::AbstractStaticSystem, inval, inidxs, outidxs)
#     nin = length(component.input)
#     outputfunc = component.outputfunc
#     function gf(ut)
#         u, t = ut
#         uu = zeros(nin) 
#         val = map(f -> f(t), inval) 
#         uu[inidxs] .= val
#         uu[filter(i -> i ∉ inidxs, 1 : nin)] .= u
#         out = outputfunc(uu, t)
#         typeof(out) <: Real ? ([out], t) : (out, t)
#     end
# end

# # Returns `true` if `innbrs` and `outnbrs` are inside loop. 
# function areinside(innbrs, outnbrs, loop)
#     isempty(filter(v -> v ∉ loop, innbrs)) && isempty(filter(v -> v ∉ loop, outnbrs))
# end

# # Returns loop functions of nodes of `loop`. 
# function loopnodefuncs(model, loop)
#     graph = model.graph
#     nodefuncs = Vector{Function}(undef, length(loop))
#     for (k, idx) in enumerate(loop)
#         loopcomponent = model[idx].component
#         innbrs, outnbrs = inneighbors(graph, idx), outneighbors(graph, idx)
#         if areinside(innbrs, outnbrs, loop)
#             if loopcomponent isa AbstractStaticSystem
#                 nodefunc = (ut) -> (loopcomponent.outputfunc(ut[1], ut[2]), ut[2])
#             elseif loopcomponent isa AbstractDynamicSystem
#                 nodefunc = (ut) -> loopcomponent.outputfunc(loopcomponent.state, ut[1], ut[2])
#             else
#                 msg = "Expected loop component of type `AbstractStaticSystem` or `AbstractDynamicSystem`"
#                 msg *= "Got typeof(loopcomponent)"
#                 error(msg)
#             end
#         else 
#             nodeinvals = []
#             nodeinidxs = Int[]
#             for innbr in filter(idx -> idx ∉ loop, innbrs)
#                 inbranch = model[innbr => idx]
#                 innbrcomponent = model[innbr].component
#                 if innbrcomponent isa AbstractSource
#                     nodeinval = t -> [innbrcomponent.outputfunc(t)...][inbranch.edgepair.pair.first]
#                 elseif innbrcomponent isa AbstractDynamicSystem 
#                     nodeinval = t -> begin 
#                         out = innbrcomponent.input === nothing ? 
#                         innbrcomponent.outputfunc(nothing, innbrcomponent.state, t) : error("One step further")
#                         out[inbranch.edgepair.pair.first]
#                     end
#                 else 
#                     error("One step futher")
#                 end
#                 push!(nodeinvals, nodeinval)
#                 append!(nodeinidxs, inbranch.edgepair.pair.second)
#             end
#             outnbr = filter(idx -> idx ∈ loop, outnbrs)[1]
#             outbranch = model[idx => outnbr]
#             nodefunc = wrap(loopcomponent, nodeinvals, nodeinidxs, outbranch.edgepair.pair.first)    
#         end
#         nodefuncs[k] = nodefunc
#     end
#     nodefuncs
# end


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

##### Plotting model
"""
    signalflow(model, args...; kwargs...)

Plots the signal flow of `model`. `args` and `kwargs` are passed into [`gplot`](https://github.com/JuliaGraphs/GraphPlot.jl) function.
"""
signalflow(model::Model, args...; kwargs...) = 
    gplot(model.graph, args...; nodelabel=[node.label for node in model.nodes], kwargs...)
