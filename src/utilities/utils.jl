# This file includes utiliti functions for Systems module

macro siminfo(msg...)
    quote
        @info "$(now()) $($msg...)"
    end
end

 
macro def(name, code)
    quote
        macro $(esc(name))()
            esc($(Meta.quot(code)))
        end
    end
end

hasargs(func, n) = n + 1 in [method.nargs for method in methods(func)]

allstates(x, u, t) = x

function unwrap(container, etype; depth=10)
    for i in 1 : depth
        container = vcat(container...)
        eltype(container) == etype && break
    end
    container
end

function construct_interpolant(input, t)
    if typeof(input) <: Inport
            inputval = rand(datatype(input), length(input))
            interpolant = Interpolant(t, Inf, inputval, inputval)
    else
        interpolant = nothing
    end
    interpolant
end

function construct_integrator(deproblem, input, statefunc, state, t, modelargs=(), solverargs=(); 
    alg=nothing, stateder=state,
    modelkwargs=NamedTuple(), solverkwargs=NamedTuple()) 
    if deproblem == SDEProblem 
        problem = deproblem(statefunc[1], statefunc[2], state, (t, Inf), construct_interpolant(input, t), modelargs...; modelkwargs...)
    elseif deproblem == DDEProblem
        problem = deproblem(statefunc[1], state, statefunc[2], (t, Inf), construct_interpolant(input, t), modelargs...; modelkwargs...)
    elseif deproblem == DAEProblem
        problem = deproblem(statefunc, stateder, state, (t, Inf), construct_interpolant(input, t), modelargs...; modelkwargs...)
    else
        problem = deproblem(statefunc, state, (t, Inf), construct_interpolant(input, t), modelargs...; modelkwargs...)
    end
    init(problem, alg, solverargs...; save_everystep=false, dense=true, solverkwargs...)
end

