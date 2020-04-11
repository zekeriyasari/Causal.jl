# This file includes the scope


"""
    Scope(input::Bus, buflen::Int=64, plugin=nothing, args...; kwargs...)

Constructs a `Scope` with input bus `input`. `buflen` is the length of the internal buffer of `Scope`. `plugin` is the additional data processing tool. `args`,`kwargs` are passed into `plots(args...; kwargs...))`. See (https://github.com/JuliaPlots/Plots.jl) for more information.

!!! warning 
    When initialized, the `plot` of `Scope` is closed. See [`open(sink::Scope)`](@ref) and [`close(sink::Scope)`](@ref).
"""
mutable struct Scope{IB, DB, TB, PL, TR, HS, CB, PLT} <: AbstractSink
    @generic_sink_fields
    plt::PLT
    function Scope(input::Inport{<:Inpin{T}}=Inport(), args...; buflen::Int=64, plugin=nothing, callbacks=nothing, 
        name=Symbol(), kwargs...) where T
        # Construct the plot 
        plt = plot(args...; kwargs...)
        foreach(sp -> plot!(sp, zeros(1)), plt.subplots)  # Plot initialization 
        timebuf = Buffer(buflen)
        databuf = Buffer(T, length(input), buflen)
        id = uuid4()
        callbacks = fasten(plugin, update, timebuf, databuf, callbacks, id)
        trigger = Inpin()
        handshake = Outpin{Bool}()
        new{typeof(input), typeof(databuf), typeof(timebuf), typeof(plugin), typeof(trigger), typeof(handshake), 
            typeof(callbacks), typeof(plt)}(input, databuf, timebuf, plugin, trigger, handshake, callbacks, name, id, 
            plt)
    end
end

show(io::IO, scp::Scope) = print(io, "Scope(nin:$(length(scp.input)))")

"""
    update(s::Scope, x, yi)

Updates the series of the plot windows of `s` with `x` and `yi`.
"""
function update(s::Scope, x, yi)
    y = collect(hcat(yi...)')
    plt = s.plt
    subplots = plt.subplots
    clear.(subplots)
    plot!(plt, x, y, xlim=(x[1], x[end]), label="")  # Plot the new series
    gui()
end

clear(sp::Plots.Subplot) = popfirst!(sp.series_list)  # Delete the old series 

""" 
    close(sink::Scope)

Closes the plot window of the plot of `sink`.
"""
close(sink::Scope) = closeall()

"""
    open(sink::Scope)

Opens the plot window for the plots of `sink`.
"""
open(sink::Scope) = Plots.isplotnull() ? (@warn "No current plots") : gui()
