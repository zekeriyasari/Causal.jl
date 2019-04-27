# This file constains the callbacks for event monitoring.


mutable struct Callback{C, A}
    condition::C
    action::A
    enabled::Bool
    name::String
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
enable!(clb::Callback) = clb.enabled = true
disable!(clb::Callback) = clb.enabled = false

##### Callback calls
@inline function (clb::Callback)(obj)
    if clb.enabled && clb.condition(obj)
        clb.action(obj)
    end
end

@inline @inbounds (clbs::Vector{Callback})(obj) = foreach(clb -> clb(obj), clbs)

"""
    hasargs(func, n)

Return true if `func` has at least one method having `n` number of arguments.
"""
hasargs(func, n) = n + 1 in [method.nargs for method in methods(func)]
