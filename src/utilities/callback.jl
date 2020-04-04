# This file constains the callbacks for event monitoring.

"""
    Callback(condition, action)

Constructs a `Callback` from `condition` and `action`. The `condition` and `action` must be a single-argument function. The `condition` returns `true` if the condition it checks occurs, otherwise, it returns `false`. `action` performs the specific action for which the `Callback` is constructed. A `Callback` can be called by passing its single argument which is mostly bound to the `Callback`.

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
mutable struct Callback{CN, AC}
    condition::CN       
    action::AC     
    enabled::Bool
    id::UUID
    Callback(condition::CN, action::AC) where {CN, AC} = new{CN, AC}(condition, action, true, uuid4()) 
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
(clbs::AbstractVector{CB})(obj) where CB<:Callback = foreach(clb -> clb(obj), clbs)
applycallbacks(obj) = typeof(obj.callbacks) <: Nothing || obj.callbacks(obj)
