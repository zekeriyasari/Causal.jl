# This file includes the usage of links and busses.
using JuSDL 

# Writing in toe 
l = Link(10)
t = launch(l)
for val in 1.:10.
    put!(l, val)
    @show l.buffer.data
end
close(l)
istaskdone(t)

