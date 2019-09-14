
function taker(channel)
    while true 
        val = take!(channel)
        val === nothing && break
        @info "Took " val
    end
end

putter(valrange) = channel -> foreach(val -> put!(channel, val), valrange)

function launcher(link)
    taskref = Ref{Task}()
    channel = Channel(channel -> begin 
        while true
            val = take!(channel)
            val === nothing && break
            @info "Took " val
        end
    end; taskref=taskref)
    taskref, channel
end
function launcher(link, valrange)
    taskref = Ref{Task}()
    channel = Channel(channel -> foreach(val -> put!(channel, val), valrange); taskref=taskref)
    taskref, channel
end

