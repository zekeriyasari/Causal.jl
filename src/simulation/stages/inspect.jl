
export inspect!

"""
    $(SIGNATURES)

Inspects the `model`. If `model` has some inconsistencies such as including algebraic loops or unterminated busses and 
error is thrown.
"""
function inspect!(model, breakpoints::Vector{Int}=Int[])
    # Check unbound pins in ports of components
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
    $(SIGNATURES)

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
    $(SIGNATURES)

Breaks the algebraic `loop` of `model`. The `loop` of the `model` is broken by inserting a `Memory` at the `breakpoint` 
of loop.
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

# Check if components of nodes of the models has unbound pins. In case there are any unbound pins, 
# the simulation is got stuck since the data flow through an unbound pin is not possible.
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

# Checks if all the channels the links in the model is open. If a link is not open, than 
# it is not possible to bind a task that reads and writes data from the channel.
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
