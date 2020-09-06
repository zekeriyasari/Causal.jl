
export addnode!, addbranch!, getnode, getbranch, getcomponent, getlinks, deletebranch!

"""
    $(SIGNATURES)

Adds a node to `model`. Component is `component` and `label` is `label` the label of node. Returns added node.

# Example 
```julia 
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
    $(SIGNATURES)

Returns node of `model` whose index is `idx`

# Example
```julia
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
getnode(model::Model, label) = only(filter(node -> node.label === label, model.nodes))

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
    $(SIGNATURES)

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

"""
    $(SIGNATURES)

Returns branch of the `model` that connects the node pair `nodepair`.
"""
getbranch(model::Model, nodepair::Pair{Int, Int}) = filter(branch -> branch.nodepair == nodepair, model.branches)[1]
getbranch(model::Model, nodepair::Pair{Symbol, Symbol}) = 
    getbranch(model, getnode(model, nodepair.first).idx => getnode(model, nodepair.second).idx)

""" 
    $(SIGNATURES)

Returns the links of `model` corresponding to the `pair` which can be a pair of integers or symbols to specify the source and destination nodes of the branch.
"""
getlinks(model::Model, pair) = getbranch(model, nodepair).links

"""
    $(SIGNATURES)

Deletes `branch` from branches of `model`.
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

