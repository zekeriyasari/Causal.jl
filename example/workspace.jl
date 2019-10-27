using LightGraphs
using GraphPlot

g = path_graph(5)
w = Dict(zip(edges(g), zeros(length(edges(g)))))
for ed in edges(g)
    red = Edge(dst(ed), src(ed))
    for i in 1 : nv(g)
        for j in i + 1 : nv(g)
            path_ij = a_star(g, i, j) 
            if ed in path_ij || red in path_ij
                w[ed] += 1
            end
        end
    end
end

conmat = zeros(nv(g), nv(g))
for (e, v) in w
    conmat[src(e), dst(e)] = v
    conmat[dst(e), src(e)] = v
end

for i in 1 : nv(g)
    conmat[i, i] = -sum(conmat[i, :])
end