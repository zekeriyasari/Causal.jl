
struct Object1
    x::Int 
    y::Float64
    z::Symbol
end

struct Object2
    x::Int 
    y::Float64
    z::Symbol
end

defaults = Dict(
    Object1 => Dict(:x => 1, :y => 4., :z => :name),
    Object2 => Dict(:x => 3, :y => 5., :z => :surname)
)
function checkdefaults(obj) 
    for (k, v) in defaults[typeof(obj)]
        getfield(obj, k) == v ||  error("Not eqaul")
    end
end

obj1 = Object1(1, 4., :name)
checkdefaults(obj1)


