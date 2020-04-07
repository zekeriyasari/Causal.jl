using Jusdl 
using LightGraphs, MetaGraphs


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


function loopvertexfuncs(model, loop)
    vertexfuncs = Vector{Function}(undef, length(loop))
    for (k, vertex) in enumerate(loop)
        vertexcomponent = getcomponent(model, vertex)
        innbrs, outnbrs = inneighbors(graph, vertex), outneighbors(graph, vertex)
        if neighborsinside(loop, innbrs, outnbrs)
            vertexfunc = vertexcomponent.outputfunc
        else 
            vertexinvals = Float64[]
            vertexinidxs = Int[]
            for innbr in filter(vertex -> vertex ∉ loop, innbrs)
                innbroutidx = getconnection(model, innbr, vertex, :srcidx)
                vertexinidx = getconnection(model, innbr, vertex, :dstidx)
                innbrcomponent = getcomponent(model, innbr)
                if innbrcomponent isa AbstractSource
                    vertexinval = [innbrcomponent.outputfunc(0.)...][innbroutidx]
                elseif innbrcomponent isa AbstractDynamicSystem 
                    out  = innbrcomponent.input === nothing ? 
                        innbrcomponent.outputfunc(nothing, innbrcomponent.state, 0.) : error("One step further")
                    vertexinval = out[innbroutidx...]
                else 
                    error("One step futher")
                end
                append!(vertexinvals, vertexinval)
                append!(vertexinidxs, vertexinidx)
            end
            outnbr = filter(vertex -> vertex ∈ loop, outnbrs)[1]
            vertexoutidxs = getconnection(model, vertex, outnbr, :srcidx)
            vertexnuminput = length(vertexcomponent.input)
            vertexfunc = wrap(vertexcomponent, vertexinvals, vertexoutidxs, vertexoutidxs)    
        end
        vertexfuncs[k] = vertexfunc
    end
    vertexfuncs
end

# Construct feedforward function from vertex loop functions 
feedforward(vertexfuncs, breakpoint=0) = x -> ∘(vertexfuncs...) - x

###################################### 
model = Model()
addcomponent(model, FunctionGenerator(sin, name=:gen))
addcomponent(model, Adder(Inport(2), (+, -), name=:adder))
addcomponent(model, Gain(Inport(), name=:gain))
addconnection(model, :gen, :adder, 1, 1)
addconnection(model, :adder, :gain)
addconnection(model, :gain, :adder, 1, 2)
graph = model.graph

# Detect algrebraic loops
loops = simplecycles(graph)
loop = loops[1]
vertexfuncs = loopvertexfuncs(model, loop)

