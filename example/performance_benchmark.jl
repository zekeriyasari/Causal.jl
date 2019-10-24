
# This file includes the performance overhead of the data passing through the channel is a union type.

using BenchmarkTools

struct Poison end 

function f()
    chnl = Channel(c->foreach(i->put!(c,i), 1:10000), ctype=Int)
    while isready(chnl)
        take!(chnl)
    end
end

function g()
    chnl = Channel(c->foreach(i->put!(c,i), 1.:10000.), ctype=Float64)
    while isready(chnl)
        take!(chnl)
    end
end

function h()
    chnl = Channel(c->foreach(i->put!(c, Poison()), 1:10000), ctype=Poison)
    while isready(chnl)
        take!(chnl)
    end
end

function k()
    chnl = Channel(c->foreach(i->put!(c, Poison()), 1:1000), ctype=Union{Poison, Float64})
    while isready(chnl)
        take!(chnl)
    end
end

f()
g()
h()
k()
display(@benchmark f())
display(@benchmark g())
display(@benchmark h())
display(@benchmark k())
