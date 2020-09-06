
export signalflow

"""
    $(SIGNATURES)

Plots the signal flow of `model`. `args` and `kwargs` are passed into [`gplot`](https://github.com/JuliaGraphs/GraphPlot.jl) function.
"""
signalflow(model::Model, args...; kwargs...) = 
    gplot(model.graph, args...; nodelabel=[node.label for node in model.nodes], kwargs...)
