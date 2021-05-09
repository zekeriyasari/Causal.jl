# This file includes the Model object

"""
    $TYPEDEF

Constructs a model `Node` with `component`. `idx` is the index and `label` is label of `Node`.

# Fields 

    $TYPEDFIELDS
"""
struct Node{CP, L}
    "Node component"
    component::CP 
    "Node index"
    idx::Int    
    "Node label"
    label::L 
end

show(io::IO, node::Node) = print(io, "Node(component:$(node.component), idx:$(node.idx), label:$(node.label))")

""" 
    $TYPEDEF

Constructs a `Branch` connecting the first and second element of `nodepair` with `links`. `indexpair` determines the
subindices by which the elements of `nodepair` are connected.

# Fields 

    $TYPEDFIELDS
"""
struct Branch{NP, IP, LN<:AbstractVector{<:Link}}
    "Node pair connected by the branch"
    nodepair::NP 
    "Indices of output and input ports"
    indexpair::IP 
    "Links of the branch"
    links::LN
end

show(io::IO, branch::Branch) = print(io, "Branch(nodepair:$(branch.nodepair), indexpair:$(branch.indexpair), ",
    "links:$(branch.links))")

"""
    $TYPEDEF

A `Model` consists of nodes and branches. Nodes are connected to each other through the branches. A `Model` instance is ready
for simulation.

See also [`Node`](@ref), [`Branch`](@ref)

# Fields 

    $SIGNATURES

!!! warning `Model`s are units that can be simulated. As the data flows through the branches i.e. input output busses of the
    components, its is important that the components must be connected to each other. See also: [`simulate!`](@ref)
"""
struct Model{GR, ND, BR, TM, CB}
    "Model graph coreesponding to the block diagram of the model"
    graph::GR
    "Model nodes. Components are added to the model in forms of nodes"
    nodes::ND
    "Model branches. Components are connected throguh branches"
    branches::BR 
    "Task manager to monitor the tasks of the model"
    taskmanager::TM
    "Callback set. [`Callback`](@ref)"
    callbacks::CB
    "Name of the model"
    name::Symbol
    "Unique identifier"
    id::UUID
    function Model(nodes::AbstractVector=[], branches::AbstractVector=[]; callbacks=nothing, name=Symbol())
        graph = SimpleDiGraph()
        taskmanager = TaskManager()
        new{typeof(graph), typeof(nodes), typeof(branches), typeof(taskmanager),
            typeof(callbacks)}(graph, nodes, branches, taskmanager, callbacks, name, uuid4())
    end
end

show(io::IO, model::Model) = print(io, "Model(numnodes:$(length(model.nodes)), numedges:$(length(model.branches)))")


##### Addinng nodes and branches.
"""
    $SIGNATURES

Adds a node to `model`. Component is `component` and `label` is `label` the label of node. Returns added node.

# Example 
```jldoctest 
julia> model = Model()
Model(numnodes:0, numedges:0, timesettings=(0.0, 0.01, 1.0))

julia> addnode!(model, SinewaveGenerator(), label=:gen)
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)
```
"""
function addnode!(model::Model, component::AbstractComponent; label=nothing)
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

julia> addnode!(model, SinewaveGenerator(), label=:gen)
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)

julia> addnode!(model, Gain(), label=:gain)
Node(component:Gain(gain:1.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64})), idx:2, label:gain)

julia> getnode(model, :gen)
Node(component:SinewaveGenerator(amp:1.0, freq:1.0, phase:0.0, offset:0.0, delay:0.0), idx:1, label:gen)

julia> getnode(model, 2)
Node(component:Gain(gain:1.0, input:Inport(numpins:1, eltype:Inpin{Float64}), output:Outport(numpins:1, eltype:Outpin{Float64})), idx:2, label:gain)
```
"""
getnode(model::Model, idx::Int) = model.nodes[idx]
getnode(model::Model, label) = filter(node -> node.label === label, model.nodes)[1]

"""
    $(SIGNATURES)

Returns the component of `model` corresponding to `specifier` that can be either index or label of the component.
"""
getcomponent(model::Model, specifier) = getnode(model, specifier).component

function register(taskmanager, component)
    triggerport, handshakeport = taskmanager.triggerport, taskmanager.handshakeport
    triggerpin, handshakepin = Outpin(), Inpin{Bool}()
    connect!(triggerpin, component.trigger)
    connect!(component.handshake, handshakepin)
    push!(triggerport.pins, triggerpin)
    push!(handshakeport.pins, handshakepin)
    taskmanager.pairs[component] = nothing
end

"""
    $SIGNATURES

Adds `branch` to branched of `model`.
"""
function addbranch!(model::Model, nodepair::Pair, indexpair::Pair=(:)=>(:))
    srcnode, dstnode = getnode(model, nodepair.first), getnode(model, nodepair.second)
    links = connect!(srcnode.component.output[indexpair.first], dstnode.component.input[indexpair.second])
    typeof(links) <: AbstractVector{<:Link} || (links = [links])
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
    $(SIGNATURES)

Returns the links of `model` corresponding to the `pair` which can be a pair of integers or symbols to specify the source and
destination nodes of the branch.
"""
getlinks(model::Model, pair) = getbranch(model, nodepair).links

"""
    deletebranch!(model::Model, branch::Branch)

Deletes `branch` from branched of `model`.

    deletebranch!(model::Model, srcnode::Node, dstnode::Node) 

Deletes branch between `srcnode` and `dstnode` of the `model`.
"""
function deletebranch!(model::Model, nodepair::Pair{Int, Int})
    srcnode, dstnode = getnode(model, nodepair.first), getnode(model, nodepair.second)
    branch = getbranch(model, nodepair)
    srcidx, dstidx = branch.indexpair
    disconnect!(srcnode.component.output[srcidx], dstnode.component.input[dstidx])
    deleteat!(model.branches, findall(br -> br == branch, model.branches))
    rem_edge!(model.graph, srcnode.idx, dstnode.idx)
    branch
end
deletebranch!(model::Model, nodepair::Pair{Symbol, Symbol}) = 
    deletebranch!(model, getnode(model, nodepair.first).idx, getnode(model, nodepair.second).idx)


##### Model inspection.
"""
    $SIGNATURES

Inspects the `model`. If `model` has some inconsistencies such as including algebraic loops or unterminated busses and error
is thrown.
"""
function inspect!(model, breakpoints::Vector{Int}=Int[])
    # Check unbound pins in ports of componensts 
    checknodeports(model) 

    # Check links of the model 
    checkchannels(model)

    # Break algebraic loops if there exits. 
    loops = getloops(model)
    if !isempty(loops)
        msg = "\tThe model has algrebraic loops:$(loops)"
        msg *= "\n\t\tTrying to break these loops..."
        @info msg
        while !isempty(loops)
            loop = popfirst!(loops)
            if hasmemory(model, loop)
                @info "\tLoop $loop has a Memory component.  The loops is broken"
                continue
            end
            breakpoint = isempty(breakpoints) ? length(loop) : popfirst!(breakpoints)
            breakloop!(model, loop, breakpoint)
            @info "\tLoop $loop is broken"
            loops = getloops(model)
        end
    end

    # Return model
    model
end

hasmemory(model, loop) = any([getnode(model, idx).component isa Memory for idx in loop])

"""
    $SIGNATURES

Returns idx of nodes that constructs algrebraic loops.
"""
getloops(model::Model) = simplecycles(model.graph)

# LoopBreaker to break the loop
@def_static_system struct LoopBreaker{OP, RO} <: AbstractStaticSystem
    input::Nothing = nothing 
    output::OP
    readout::RO
end


"""
    $SIGNATURES

Breaks the algebraic `loop` of `model`. The `loop` of the `model` is broken by inserting a `Memory` at the `breakpoint` of
loop.
"""
function breakloop!(model::Model, loop, breakpoint=length(loop)) 
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
        breaker = LoopBreaker(readout = (u,t) -> findroot(ff, n, t), output=Outport(n))
    else 
        component = srcnode.component
        n = length(component.output) 
        breaker = LoopBreaker(readout = (u,t)->component.readout(component.state, nothing, t), output=Outport(n))
    end 
    # newidx = length(model.nodes) + 1 
    newnode = addnode!(model, breaker)
    
    # Delete the branch at the breakpoint
    deletebranch!(model, branch.nodepair)
    
    # Connect the loopbreker to the loop at the breakpoint.
    addbranch!(model, newnode.idx => dstnode.idx, branch.indexpair)
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
_computeoutput(comp::AbstractStaticSystem, u, t) = comp.readout(u, t)
_computeoutput(comp::AbstractDynamicSystem, u, t) = comp.readout(comp.state, map(uu -> t -> uu, u), t)

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
            component.readout(nothing, 0.) : component.readout(component.state, nothing, 0.)
        return false
    catch ex 
        return true 
    end
end

# Check if components of nodes of the models has unbound pins. In case there are any unbound pins, the simulation is got
# stuck since the data flow through an unbound pin is not possible.
checknodeports(model) = foreach(node -> checkports(node.component), model.nodes)
function checkports(comp::T) where T  
    if hasfield(T, :input)
        idx = unboundpins(comp.input)
        isempty(idx) || error("Input port of $comp has unbound pins at index $idx")
    end 
    if hasfield(T, :output)
        idx = unboundpins(comp.output)
        isempty(idx) || error("Output port of $comp has unbound pins at index $idx")
    end 
end
unboundpins(port::AbstractPort) = findall(.!isbound.(port)) 
unboundpins(port::Nothing) = Int[]

# Checks if all the channels the links in the model is open. If a link is not open, than it is not possible to bind a task
# that reads and writes data from the channel.
function checkchannels(model)
    # Check branch links 
    for branch in model.branches 
        for link in branch.links 
            isopen(link) || refresh!(link)
        end
    end
    # Check taskmanager links 
    for pin in model.taskmanager.triggerport 
        link = only(pin.links)
        isopen(link) || refresh!(link) 
    end
    for pin in model.taskmanager.handshakeport 
        link = pin.link
        isopen(link) || refresh!(link) 
    end
end

##### Model initialization

"""
    $(SIGNATURES)

Initializes `model` by launching component task for each of the component of `model`. The pairs component and component tasks
are recordedin the task manager of the `model`. The `model` clock is [`set!`](@ref) and the files of [`Writer`](@ref) are
openned.
"""
function initialize!(model::Model, clock::Clock)
    # NOTE: Tasks to make the components be triggerable are launched here. The important point here is that the simulation
    # should be cancelled if an error is thrown in any of the tasks launched here. This is done by binding the task to the
    # chnnel of the trigger link of the component. Hrence the lifetime of the channel of the link connecting the component to
    # the taskmanger is determined by the lifetime of the task launched for the component. To cancel the simulation and
    # report the stacktrace the task is `fetch`ed. 
    bind!(model)

    # Reset dynamical systems 
    resetdynamicalsystems!(model, clock)

    # Clean the model 
    clean!(model)
    
    # Open the files, GUI's for sink components. 
    opensinks!(model)
end

# Find the link connecting `component` to `taskmanager`.
function whichlink(taskmanager, component)
    tpin = component.trigger
    tport = taskmanager.triggerport
    # NOTE: `component` must be connected to `taskmanager` by a single link which is checked by `only` `outpin.links` must
    # have just a single link which checked by `only`
    outpin = filter(pin -> isconnected(pin, tpin), tport) |> only 
    outpin.links |> only
end

# Bind tasks to connections 
function bind!(model::Model)
    taskmanager = model.taskmanager
    pairs = taskmanager.pairs
    nodes = model.nodes
    for node in nodes 
        component = node.component
        link = whichlink(taskmanager, component)  # Link connecting the component to taskmanager. 
        task = launch(component)    # Task launched to make `componnent` be triggerable.
        bind(link.channel, task)    # Bind the task to the channel of the link. 
        pairs[component] = task 
    end
    model 
end

# Open AbstractSink components 
function opensinks!(model::Model)
    foreach(node -> open(node.component), filter(node->isa(node.component, AbstractSink), model.nodes))
    model 
end 

"""
    $(SIGNATURES)

Cleans the buffers of the links of the connections, internal buffers of components, current time of dynamical systems.
"""
function clean!(model::Model)
    cleanbranches!(model)
    cleannodes!(model)
    model 
end

function cleanbranches!(model) 
    foreach(branch -> foreach(link -> clean!(link), branch.links), model.branches)
    model 
end 

function cleannodes!(model)
    foreach(node -> cleancomponent!(node.component), model.nodes)
    model
end

function cleancomponent!(comp::T) where T
    # Clean all internal buffers 
    foreach(name -> (field = getfield(comp, name); field isa Buffer && clean!(field)), fieldnames(T))
    # If comp is a Writer, renew the file.
    comp isa Writer && (close(comp); open(comp, "w"); close(comp))
    comp 
end 

function resetdynamicalsystems!(model::Model, clock::Clock)
    # Iterate model clock for the first time. Set the current time of dynamical systems to the initial time of clock.
    iter = iterate(clock) 
    iter === nothing && error("Simulation clock is not iterable.")
    t, _ = iter 
    for comp in filter(comp -> comp isa AbstractDynamicSystem, getfield.(model.nodes, :component))
        comp.t != t && (comp.t = t) 
        reinit!(comp.integrator)
        comp.input === nothing || (interp = comp.interpolant; clean!(interp.timebuf); clean!(interp.databuf))
    end
    model
end

##### Model running
# Copy-paste loop body. See `run!(model, withbar)`. NOTE: We first trigger the component, Then the tasks fo the `taskmanager`
# is checked. If an error is thrown in one of the tasks, the simulation is cancelled and stacktrace is printed reporting the
# error. In order to ensure the time synchronization between the components of the model, `handshakeport` of the taskmanger
# is read. When all the components take step succesfully, then the simulation goes with the next step after calling the
# callbacks of the components. Note we first check the tasks of the taskmanager and then read the `handshakeport` of the
# taskmanager. Otherwise, the simulation gets stuck without printing the stacktrace if an error occurs in one of the tasks of
# the taskmanager.
@def loopbody begin 
    put!(triggerport, fill(t, ncomponents))
    checktaskmanager(taskmanager)          
    all(take!(handshakeport)) || @warn "Taking step could not be approved."
    applycallbacks(model)
end

"""
    $SIGNATURES

Runs the `model` by triggering the components of the `model`. This triggering is done by generating clock tick using the
model clock `model.clock`. Triggering starts with initial time of model clock, goes on with a step size of the sampling
period of the model clock, and finishes at the finishing time of the model clock. If `withbar` is `true`, a progress bar
indicating the simulation status is displayed on the console.

!!! warning 
    The `model` must first be initialized to be run. See also: [`initialize!`](@ref).
"""
function run!(model::Model, clock::Clock, withbar::Bool=true)
    taskmanager = model.taskmanager
    triggerport, handshakeport = taskmanager.triggerport, taskmanager.handshakeport
    ncomponents = length(model.nodes)
    T = typeof(clock.generator)
    withbar && hasmethod(length, Tuple{T}) ? (@showprogress for t in clock @loopbody end) : (for t in clock @loopbody end)
    model
end

# ##### Model termination
"""
    $SIGNATURES

Terminates `model` by terminating all the components of the `model`, i.e., the components tasks in the task manager of the
`model` is terminated.
"""
function terminate!(model::Model)
    taskmanager = model.taskmanager
    tasks = unwrap(collect(values(taskmanager.pairs)), Task, depth=length(taskmanager.pairs))
    any(istaskstarted.(tasks)) && put!(taskmanager.triggerport, fill(NaN, length(model.nodes)))
    model
end


##### Model simulation.
function _simulate(sim::Simulation, reportsim::Bool, withbar::Bool, breakpoints::Vector{Int})
    model, clock = sim.model, sim.clock
    @siminfo "Started simulation..."
    sim.state = :running

    @siminfo "Inspecting model..."
    inspect!(model, breakpoints)
    @siminfo "Done."

    @siminfo "Initializing the model..."
    initialize!(model, clock)
    @siminfo "Done..."

    @siminfo "Running the simulation..."
    run!(model, clock, withbar)
    sim.state = :done
    sim.retcode = :success
    @siminfo "Done..."
    
    @siminfo "Terminating the simulation..."
    terminate!(model)
    @siminfo "Done."

    reportsim && report(sim)
    return sim
end

"""
    $SIGNATURES

Simulates `model`. `simdir` is the path of the directory into which simulation files are saved. `simprefix` is the prefix of
the simulation name `simname`. If `logtofile` is `true`, a log file for the simulation is constructed. `loglevel` determines
the logging level. If `reportsim` is `true`, model components are saved into files. If `withbar` is `true`, a progress bar
indicating the simualation status is displayed on the console.
"""
function simulate!(model::Model, clock::Clock; 
                   simdir::String=tempdir(), 
                   simprefix::String="Simulation-", 
                   simname=string(uuid4()),
                   logtofile::Bool=false, 
                   loglevel::LogLevel=Logging.Info, 
                   reportsim::Bool=false, 
                   withbar::Bool=true, 
                   breakpoints::Vector{Int}=Int[])
    
    # Construct a Simulation
    sim = Simulation(model, clock, simdir=simdir, simprefix=simprefix, simname=simname)
    sim.logger = logtofile ? 
        SimpleLogger(open(joinpath(sim.path, "simlog.log"), "w+"), loglevel) : 
        ConsoleLogger(stderr, loglevel)

    # Simualate the modoel
    with_logger(sim.logger) do
        _simulate(sim, reportsim, withbar, breakpoints)
    end
    logtofile && flush(sim.logger.stream)  # Close logger file stream.
    return sim
end

""" 
    $SIGNATURES

Simulates the `model` starting from the initial time `t0` until the final time `tf` with the sampling interval of `tf`. For
`kwargs` are 

* `logtofile::Bool`: If `true`, a log file is contructed logging each step of the simulation. 
* `reportsim::Bool`: If `true`, `model` components are written files after the simulation. When this file is read back, the
  model components can be consructed back with their status at the end of the simulation.
* `simdir::String`: The path of the directory in which simulation file are recorded. 
"""
simulate!(model::Model, ti::Real, dt::Real, tf::Real; kwargs...) = simulate!(model, Clock(ti:dt:tf); kwargs...)

#### Troubleshooting 
"""
    $SIGNATURES

Prints the exceptions of the tasks that are failed during the simulation of `model`.
"""
function troubleshoot(model::Model)
    fails = filter(pair -> istaskfailed(pair.second), model.taskmanager.pairs)
    if isempty(fails)
        @info "No failed tasks in $model."
    else
        for (comp, task) in fails
            println("", comp)
            @error task.exception
        end
    end
end

##### Plotting signal flow of the model 
"""
    $SIGNATURES

Plots the signal flow of `model`. `args` and `kwargs` are passed into [`gplot`](https://github.com/JuliaGraphs/GraphPlot.jl)
function.
"""
signalflow(model::Model, args...; kwargs...) = 
    gplot(model.graph, args...; nodelabel=[node.label for node in model.nodes], kwargs...)


##### @model macro

function check_macro_syntax(name, ex)
    name isa Symbol || error("Invalid usage of @model")
    ex isa Expr && ex.head == :block || error("Invalid usage of @model")
end

function check_block_syntax(node_expr, branch_expr)
    #-------------------  Node expression check --------------- Check syntax the following syntax @nodes begin label1 =
    # Component1() label2 = Component2() ⋮ end 
    (
        node_expr isa Expr && 
        node_expr.head === :(macrocall) && 
        node_expr.args[1] === Symbol("@nodes")
    ) ||  error("Invalid usage of @nodes")
    node_block = node_expr.args[3]
    (
        node_block.head === :block && 
        all([ex.head === :(=) for ex in filter(arg -> isa(arg, Expr), node_block.args)])
    ) || error("Invalid usage of @nodes")

    #---------------------  Branch expression check -------------- Check syntax the following syntax @branches begin
    # src1[srcidx1] => dst1[dstidx1] src2[srcidx2] => dst2[dstidx2] ⋮ end 
    (
        branch_expr isa Expr && 
        branch_expr.head === :(macrocall) && 
        branch_expr.args[1] === Symbol("@branches") 
    ) || error("Invalid usage of @branches")
    branch_block = branch_expr.args[3]
    (
        branch_block.head === :block && 
        all([ex.head === :call && ex.args[1] == :(=>) for ex in filter(arg -> isa(arg, Expr), branch_block.args)])
    ) || error("Invalid usage of @branches")
end

"""
    @defmodel name ex 

Construts a model. The expected syntax is. 
```
    @defmodel mymodel begin 
        @nodes begin 
            label1 = Component1()
            label2 = Component1()
                ⋮
        end
        @branches begin 
            src1 => dst1 
            src2 => dst2 
                ⋮
        end
    end
```
Here `@nodes` and `@branches` blocks adefine the nodes and branches of the model, respectively. 
"""
macro defmodel(name, ex) 
    # Check syntax 
    check_macro_syntax(name, ex) 
    node_expr = ex.args[2]
    branch_expr = ex.args[4]
    check_block_syntax(node_expr, branch_expr)

    # Extract nodes info
    node_block = node_expr.args[3] 
    node_labels = [expr.args[1] for expr in node_block.args if expr isa Expr]
    node_components = [expr.args[2] for expr in node_block.args if expr isa Expr]

    # Extract branches info 
    branch_block = branch_expr.args[3] 
    lhs = [expr.args[2] for expr in filter(ex -> isa(ex, Expr), branch_block.args)]
    rhs = [expr.args[3] for expr in filter(ex -> isa(ex, Expr), branch_block.args)]
    quote 
        # Construct model 
        $name = Model()

        # Add nodes to model  
        for (node_label, node_component) in zip($node_labels, $node_components)
            addnode!($name, eval(node_component), label=node_label)
        end

        # Add braches to model 
        for (src, dst) in zip($lhs, $rhs)
            if src isa Symbol && dst isa Symbol 
                addbranch!($name, src => dst)
            elseif src isa Expr && dst isa Expr # src and dst has index.
                if src.args[2] isa Expr && dst.args[2] isa Expr     
                    # array or range index.
                    addbranch!($name, src.args[1] => dst.args[1], eval(src.args[2]) => eval(dst.args[2]))
                else   
                    # integer index
                    addbranch!($name, src.args[1] => dst.args[1], src.args[2] => dst.args[2])
                end
            else 
                error("Ambbiuos connection. Specify the indexes explicitely.")
            end
        end
    end |> esc
end
