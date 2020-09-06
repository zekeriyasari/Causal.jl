
export Node, Branch, Model

"""
    $(TYPEDEF) 

Components are added to [`Model`](@ref) in the form of `Nodes`. A `Node` is a model component with index `idx` and component `component`.

# Fields 
    $(TYPEDFIELDS)
"""
struct Node{CP, L}
    component::CP 
    idx::Int    
    label::L 
end

show(io::IO, node::Node) = print(io, "Node(component:$(node.component), idx:$(node.idx), label:$(node.label))")

""" 
    $(TYPEDEF) 

`Branch` are connections added to [`Model`](@ref). When nodesof a model are connected to each other with `Branches`.

# Fields 

    $(TYPEDFIELDS)
"""
struct Branch{NP, IP, LN<:AbstractVector{<:Link}}
    nodepair::NP 
    indexpair::IP 
    links::LN
end

show(io::IO, branch::Branch) = print(io, "Branch(nodepair:$(branch.nodepair), indexpair:$(branch.indexpair), ",
    "links:$(branch.links))")

"""
    $(TYPEDEF)

`Model`s are connected components ready for simulation [`simulate!`](@ref).

# Fields 

    $(TYPEDFIELDS)

!!! warning
    `Model`s are units that can be simulated. As the data flows through the branches i.e. input output busses of the components, its is important that the components must be connected to each other. See also: [`simulate!`](@ref)
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
