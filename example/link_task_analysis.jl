import Base: put!, take!, RefValue, isreadable, iswritable, show


################### Define Link

mutable struct Link{CH, B}
    channel::CH 
    buffer::B
    master::RefValue{Link{CH, B}}
    slaves::Vector{RefValue{Link{CH, B}}}
    Link(channel::CH, buffer::B) where {CH, B} = 
        new{CH, B}(channel, buffer, RefValue{Link{CH, B}}(), Vector{RefValue{Link{CH, B}}}())
end
Link() = Link(Channel(0), [])

show(io::IO, link::Link) = print(io, "Link(isreadable:$(isreadable(link)), iswritable:$(iswritable(link)))")


isreadable(link::Link) = !isempty(link.channel.cond_put)
iswritable(link::Link) = !isempty(link.channel.cond_take) 

function connect(srclink::Link, dstlink::Link)
    push!(srclink.slaves, Ref(dstlink))
    dstlink.master = Ref(srclink) 
    return  
end

function put!(link::Link, val) 
    push!(link.buffer, val)
    put!(link.channel, val)
    isempty(link.slaves) || foreach(junc -> put!(junc[], val), link.slaves)
    # isempty(link.slaves) ? put!(link.channel, val) : foreach(junc -> put!(junc[], val), link.slaves)
    return val
end

function take!(link::Link)
    val = take!(link.channel)
    return val
end

function taker(ch)
    @async while true 
        val = take!(ch)
        val === nothing && break
        @info "Took $val"
    end
end

function putter(ch, vals)
    @async for val in vals 
        put!(ch, val)  
    end
end

################# Define Object 

struct Object{T, S, P}
    input::T 
    output::S 
    trigger::P 
end

function launch(obj::Object)
    @async while true take!(obj.output) end
    @async while true 
        t = take!(obj.trigger)
        u = take!(obj.input)
        y = u 
        put!(obj.output, y)
    end
end

############################### 
obj = Object(Link(), Link(), Link())
putter(obj.input, 1. : 10.)
launch(obj)