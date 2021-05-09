# This file constains the callbacks for event monitoring.

"""
    $TYPEDEF

Constructs a `Callback` from `condition` and `action`. The `condition` and `action` must be a single-argument function. The `condition` returns `true` if the condition it checks occurs, otherwise, it returns `false`. `action` performs the specific action for which the `Callback` is constructed. A `Callback` can be called by passing its single argument which is mostly bound to the `Callback`.

# Fields 

    $TYPEDFIELDS

# Example 
```julia 
julia> struct Object  # Define a dummy type.
       x::Int 
       clb::Callback 
       end

julia> cond(obj) = obj.x > 0;  # Define callback condition.

julia> action(obj) = println("obj.x = ", obj.x); # Define callback action.

julia> obj = Object(1, Callback(condition=cond, action=action))
Object(1, Callback(condition:cond, action:action))

julia> obj.clb(obj)  # Call the callback bound `obj`.
obj.x = 1
```
"""
Base.@kwdef mutable struct Callback{CN, AC}
    "Condition function of callback. Expected to be a single-argument function"
    condition::CN = obj -> false 
    "Action of the callback. Expected to be a single-argument fucntion"
    action::AC = obj -> nothing
    "If true, callback is activated"
    enabled::Bool = true
    "Unique identifier" 
    id::UUID = uuid4()
end

show(io::IO, clb::Callback) = print(io, "Callback(condition:$(clb.condition), action:$(clb.action))")

##### Callback controls
"""
    $SIGNATURES

Enables `clb`.
"""
enable!(clb::Callback) = clb.enabled = true

"""
    $SIGNATURES

Disables `clb`.
"""
disable!(clb::Callback) = clb.enabled = false

"""
    $SIGNATURES

Returns `true` if `clb` is enabled. Otherwise, returns `false`.
"""
isenabled(clb::Callback) = clb.enabled

##### Callback calls
# Apply callback asynchronously.
# (clb::Callback)(obj) = clb.enabled && clb.condition(obj) ? clb.action(obj) : nothing
(clb::Callback)(obj) = clb.enabled && clb.condition(obj) ? (@async(clb.action(obj)); nothing) : nothing
(clbs::AbstractVector{CB})(obj) where CB<:Callback = foreach(clb -> clb(obj), clbs)

"""
    $SIGNATURES

Calls the callbacks of `obj` if the callbacks are not nothing.

# Example
```julia
julia> mutable struct MyType{CB}
       x::Int
       callbacks::CB
       end

julia> obj = MyType(5, Callback(condition=obj -> obj.x > 0, action=obj -> println("x is positive")));

julia> applycallbacks(obj)
x is positive

julia> obj.x = -1
-1

julia> applycallbacks(obj)
```
"""
applycallbacks(obj) = typeof(obj.callbacks) <: Nothing || obj.callbacks(obj)
