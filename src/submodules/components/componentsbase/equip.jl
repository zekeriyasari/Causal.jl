
export equip

"""
    $(SIGNATURES)

Equips `comp` to make it launchable. Equipment is done by constructing and connecting signalling pins (i.e. `trigger` 
and `handshake`), input and output ports (if necessary) 
"""
function equip(comp, kickoff::Bool=true)
    oport = typeof(comp) <: AbstractSource ? 
        nothing : (typeof(comp.input) === nothing  ? nothing : Outport{datatype(comp.input)}(length(comp.input)))
    iport = typeof(comp) <: AbstractSink ?  
        nothing : (typeof(comp.output) === nothing ? nothing : Inport{datatype(comp.output)}(length(comp.output)))
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
    
    # oport, iport, trg, hnd, comptask, outputtask
    # Return a NamedTuple instead 
    (
        writing_port = oport, 
        reading_port = iport, 
        trigger = trg, 
        handshake = hnd, 
        component_task = comptask, 
        reading_port_task = outputtask 
    )
end

launchport(iport) = @async while true 
    all(take!(iport) .=== NaN) && break 
end
