# This file constains the callbacks for event monitoring.

"""
    Callback[condition, action, [enabled::Bool, [name::String]])

Constructs a `Callback` with `condition` and `action`. `condition` is a single-argument function that returns true when a specific event occurs and return false, otherwise. `action` is a single-argument function that performs some specific job. When `enabled` is false, `action` is deactivated. `name` is the name of the `Callback`.  Expected syntax for `condition` function  is 
```
    function condition(obj) -> Bool 
        Even occured ? 
            return true 
        Else 
            return false
    end
```
and the expected signature for the `action` function is 
```
    function action(obj)
        Do whatever you want with obj.
    end
```
"""
mutable struct Callback{C, A}
    condition::C        # Condtion function. Returns true if a specific event occurs.
    action::A           # Action function. Performs some specific task.
    enabled::Bool       # If false, `action` function is deactivated.
    name::String        # Name of the `Callback`
    function Callback(condition::C, action::A, enabled::Bool, name::String) where {C, A}
        hasargs(condition, 1) ||
            error("Expected single argument condition, got $(methods(condition))")
        hasargs(action, 1) ||
            error("Expected single argument action, got $(methods(action))")
        new{C, A}(condition, action, enabled, name)
    end
end

Callback(condition, action; enabled=true, name=string(uuid4())) =
    Callback(condition, action, enabled, name)

##### Callback controls
"""
    enable!(clb::Callback)

Enables `clb`. If `clb` is enabled, `clb.action` is activated.
"""
enable!(clb::Callback) = clb.enabled = true

"""
    disable!(clb:Callback)

Disables `clb`. If `clb` is disabled, `clb.action` is deactivated.
"""
disable!(clb::Callback) = clb.enabled = false

##### Callback calls
@inline function (clb::Callback)(obj)
    if clb.enabled && clb.condition(obj)
        clb.action(obj)
    end
end

@inline @inbounds (clbs::Vector{Callback})(obj) = foreach(clb -> clb(obj), clbs)

hasargs(func, n) = n + 1 in [method.nargs for method in methods(func)]
