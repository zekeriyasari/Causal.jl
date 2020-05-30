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
Base.@kwdef mutable struct Callback{CN, AC}
    condition::CN = obj -> false 
    action::AC = obj -> nothing
    enabled::Bool = true 
    id::UUID = uuid4()
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
# Apply callback asynchronously.
# (clb::Callback)(obj) = clb.enabled && clb.condition(obj) ? clb.action(obj) : nothing
(clb::Callback)(obj) = clb.enabled && clb.condition(obj) ? @async(clb.action(obj)) : nothing
(clbs::AbstractVector{CB})(obj) where CB<:Callback = foreach(clb -> clb(obj), clbs)

"""
    applycallbacks(obj)

Calls the callbacks of `obj` if the callbacks are not nothing.

# Example
```jldoctest
julia> mutable struct MyType{CB}
       x::Int
       callbacks::CB
       end

julia> obj = MyType(5, Callback(obj -> obj.x > 0, obj -> println("x is positive")));

julia> applycallbacks(obj)
x is positive

julia> obj.x = -1
-1

julia> applycallbacks(obj)
```
"""
applycallbacks(obj) = typeof(obj.callbacks) <: Nothing || obj.callbacks(obj)
