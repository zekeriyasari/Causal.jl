using Jusdl 
using LightGraphs, MetaGraphs

model = Model()
addcomponent(model, FunctionGenerator(sin, name=:gen))
addcomponent(model, Adder(Inport(2), (+, -), name=:adder))
addcomponent(model, Gain(Inport(), name=:gain))
addconnection(model, :gen, :adder, 1, 1)
addconnection(model, :adder, :gain)
addconnection(model, :gain, :adder, 1, 2)
graph = model.graph

# Find loops
loops = getloops(model)

# Get one the loop
loop = loops[1]

# Find nodes having outside neighbors.
probnodeidx = falses(length(loop))
for (idx, node) in enumerate(loop)
    node_inneighbors = inneighbors(graph, node)
    node_outneighbors = outneighbors(graph, node)
    node_inneighbors_inside_loop_idx = [idx in loop for idx in node_inneighbors]
    node_outneighbors_inside_loop_idx = [idx in loop for idx in node_outneighbors]
    node_inneighbors_inside_loop = node_inneighbors[node_inneighbors_inside_loop_idx]
    node_inneighbors_outside_loop = node_inneighbors[.!node_inneighbors_inside_loop_idx]
    node_outneighbors_inside_loop = node_outneighbors[node_outneighbors_inside_loop_idx]
    node_outneighbors_outside_loop = node_outneighbors[.!node_outneighbors_inside_loop_idx]
    @show node, node_inneighbors, node_inneighbors_inside_loop, node_inneighbors_outside_loop, node_outneighbors, node_outneighbors_inside_loop, node_outneighbors_outside_loop
    has_out_of_loop_neighbor = !isempty(node_inneighbors_outside_loop) || !isempty(node_outneighbors_outside_loop)
    has_out_of_loop_neighbor && (probnodeidx[idx] = true)
end

# Conctruct partial functions
for node in loop[probnodeidx]
    component = getcomponent(model, node)
    numinput = length(comp.input)
    numoutput = length(comp.output)
    for nbr in filter(nbr -> nbr ∉ loop, inneighbors(graph, node))
        srcidx = getconnection(model, nbr, node, :srcidx) 
        dstidx = getconnection(model, nbr, node, :dstidx) 
        neighbor = getcomponent(model, nbr)
        if neighbor isa AbstractSource
            val = [neighbor.outputfunc(0.)...]
        else neighbor isa DynamicSystem 
            out = neighbor.input === nothing ? neighbor.outputfunc(neighbor.x, nothing, 0.) : error("One step further")
            val = [out...]
        end
        @show val, srcidx, dstidx, val[srcidx]
    end
end

f(u, t) = u[1] + u[2] + u[3] + u[4]
val = [10, 12]
dstidx = [1, 3]
function partial(f, val, dstidx, n)
    n = 4
    function gf(u, t)
        uu = zeros(n) 
        uu[dstidx] = val 
        uu[filter(i -> i ∉ dstidx, 1 : n)] = u
        f(uu, t)
    end
end
myfunc = partial(f, val, dstidx, 4)

