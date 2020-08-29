# This file includes utiliti functions for Systems module

export equip

macro siminfo(msg...)
    quote
        @info "$(now()) $($msg...)"
    end
end


#= 
    @def begin name 
        code 
    end

Copy paste macro
=#
macro def(name, code)
    quote
        macro $(esc(name))()
            esc($(Meta.quot(code)))
        end
    end
end

hasargs(func, n) = n + 1 in [method.nargs for method in methods(func)]

function unwrap(container, etype; depth=10)
    for i in 1 : depth
        container = vcat(container...)
        eltype(container) == etype && break
    end
    container
end


launchport(iport) = @async while true 
    all(take!(iport) .=== NaN) && break 
end

"""
    $(SIGNATURES)

Equips `comp` to make it launchable. Equipment is done by constructing and connecting signalling pins (i.e. `trigger` 
and `handshake`), input and output ports (if necessary) 
"""
function equip(comp, kickoff::Bool=true)
    oport = typeof(comp) <: AbstractSource ? 
        nothing : (typeof(comp.input) === nothing  ? nothing : Outport(length(comp.input)))
    iport = typeof(comp) <: AbstractSink ?  
        nothing : (typeof(comp.output) === nothing ? nothing : Inport(length(comp.output)))
    trg = Outpin()
    hnd = Inpin{Bool}()
    oport === nothing || connect!(oport, comp.input)
    iport === nothing || connect!(comp.output, iport)
    connect!(trg, comp.trigger)
    connect!(comp.handshake, hnd)
    if kickoff 
        comptask, outputtask = launch(comp), launchport(iport)
    else 
        comptask, outputtask = nothing, nothing
    end
    oport, iport, trg, hnd, comptask, outputtask
end