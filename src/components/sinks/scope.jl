# This file includes the scope


mutable struct Scope{DB, TB, P, PLT} <: AbstractSink
    @generic_sink_fields
    plt::PLT
    function Scope(input, buflen, plugin, callbacks, name, args...; kwargs...)
        # Construct the plot 
        plt = plot(args...; kwargs...)
        foreach(sp -> plot!(sp, zeros(1)), plt.subplots)  # Plot initialization 
        # Construct the buffers
        timebuf = Buffer(buflen)
        databuf = length(input) == 1 ? Buffer(buflen) : Buffer(buflen, length(input))
        trigger = Link()
        scope = new{typeof(databuf), typeof(timebuf), typeof(plugin), typeof(plt)}(input, databuf, timebuf, 
            plugin, trigger, callbacks, name, plt)
        add_callback(scope, update!)
    end
end
Scope(input, args...; buflen=64, plugin=nothing, callbacks=Callback[], name=string(uuid4()), kwargs...) =  
    Scope(input, buflen, plugin, callbacks, name, args...; kwargs...)

    
clear(sp::Plots.Subplot) = popfirst!(sp.series_list)  # Delete the old series 
function update!(s::Scope, x, y)
    plt = s.plt
    subplots = plt.subplots
    clear.(subplots)
    plot!(plt, x, y, xlim=(x[1], x[end]), label="")  # Plot the new series
    gui()
end

close(sink::Scope) = closeall()
open(sink::Scope) = Plots.isplotnull() ? (@warn "No current plots") : gui()
