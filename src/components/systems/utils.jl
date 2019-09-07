# This file includes utiliti functions for Systems module

hasargs(func, n) = n + 1 in [method.nargs for method in methods(func)]

function infer_number_of_outputs(func, u, t)
    hasargs(func, 2) || error("Expected method `func(u, t)` got $(methods(func))")
    if typeof(u) <: Nothing
        length(func(nothing, t))
    else
        length(func(zeros(length(u)), t))
    end
end

function infer_number_of_outputs(func, x, u, t) 
    hasargs(func, 3) || error("Expected method `func(x, u, t)` got $(methods(func))") 
    if typeof(u) <: Nothing
        length(func(x, nothing, t)) 
    else
        length(func(x, zeros(length(u)), t)) 
    end
end
    
