# This file constains the callbacks for event monitoring.

"""
    Callback(condition, action)

Constructs a `Callback` from `condition` and `action`. The `condition` and `action` must be a single-argument functions. `condition` returns `true` if the condition it checks occurs, otherwise ite returns `false`. `action` is performs the specific action for which the `Callback` the callback is contructed. A `Callback` can be called by passing its single argument which is mostly bound to the `Callback`.

# Example 

```jldoctest
julia> struct Object  # Define a dummy type.
       x::Int 
       clb::Callback 
       end 

julia> cond(obj) = obj.x > 0  # Define callback condition.
cond (generic function with 1 method)

julia> action(obj) = println("Printing the object ", obj) # Define callback action.
action (generic function with 1 method)

julia> obj = Object(1, Callback(cond, action))  # Construct an `Object` instance with `Callback`.
Object(1, Callback(condition:cond, action:action))

julia> obj.clb(obj)  # Call the callback bound `obj`.
Printing the object Object(1, Callback(condition:cond, action:action))
```
"""
mutable struct Callback{C, A}
    condition::C       
    action::A     
    enabled::Bool
    id::UUID
    Callback(condition::C, action::A) where {C, A} = new{C, A}(condition, action, true, uuid4()) 
end

show(io::IO, clb::Callback) = print(io, "Callback(condition:$(clb.condition), action:$(clb.action))")

##### Callback controls
"""
    enable!(clb::Callback)

Enables `clb`.
"""
enable!(clb::Callback) = clb.enabled = true

"""
    disable!(clb::Callback)

Disables `clb`.
"""
disable!(clb::Callback) = clb.enabled = false

"""
    isenabled(clb::Callback)

Returns `true` if `clb` is enabled. Otherwise, returns `false`.
"""
isenabled(clb::Callback) = clb.enabled

##### Callback calls
(clb::Callback)(obj) = clb.enabled && clb.condition(obj) ?  clb.action(obj) : nothing
@inbounds (clbs::Vector{Callback})(obj) = foreach(clb -> clb(obj), clbs)

##### Adding callbacks
"""
    addcallback(obj, clb::Callback, priority::Int)

Adds `clb` to callback vector of `obj` which is assumed the have a callback list which is a vector of callback.

# Example
```jldoctest
julia> mutable struct Object 
       x::Int 
       callbacks::Vector{Callback}
       Object(x::Int) = new(x, Callback[])
       end 

julia> obj = Object(5)
Object(5, Callback[])

julia> condition(val) = val.x == 5
condition (generic function with 1 method)

julia> action(val) = @show val.x 
action (generic function with 1 method)

julia> addcallback(obj, Callback(condition, action))
Object(5, Callback[Callback(condition:condition, action:action)])

julia> obj.callbacks(obj)
val.x = 5
```
"""
addcallback(obj, callback::Callback, priority::Int=1) = (insert!(obj.callbacks, priority, callback); obj)

"""
    deletecallback(obj, idx::Int)

Deletes the one of the callbacks of `obj` at index `idx`.

```jldoctest
julia> struct Object 
       x::Int 
       callbacks::Vector{Callback}
       end

julia> clb1 = Callback(val -> true, val -> nothing);

julia> clb2 = Callback(val -> false, val -> nothing);

julia> obj = Object(5, [clb1, clb2]);

julia> deletecallback(obj, 2);

julia> length(obj.callbacks) == 1
true
```
"""
deletecallback(obj, idx::Int) = (deleteat!(obj.callbacks, idx); obj)
