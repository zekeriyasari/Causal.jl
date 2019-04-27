# This file includes the testset for JuSDL.Plugins module
using JuSDL.Utilities

mutable struct Object 
    x::Int 
    callbacks::Vector{Callback}
end
condition(obj) = obj.x == 3
action(obj) = println("In th callback,", obj.x)
obj = Object(2, [Callback(condition, action)])

obj.callbacks(obj)
for x in 1 : 5
    obj.x = x
    obj.callbacks(obj)
end
