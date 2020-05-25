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

@def genericfields begin 
    trigger::TR = Inpin()
    handshake::HS = Outpin{Bool}()
    callbacks::CB = nothing
    name::Symbol = Symbol()
    id::UUID = uuid4()
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

function construct_integrator(deproblem, input, statefunc, state, t, modelargs=(), solverargs=(); 
    alg=nothing, stateder=state, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=3)
    interpolant = input === nothing ? nothing : Interpolant(numtaps, length(input))
    if deproblem == SDEProblem 
        problem = deproblem(statefunc[1], statefunc[2], state, (t, Inf), interpolant, modelargs...; modelkwargs...)
    elseif deproblem == DDEProblem
        problem = deproblem(statefunc[1], state, statefunc[2], (t, Inf), interpolant, modelargs...; modelkwargs...)
    elseif deproblem == DAEProblem
        problem = deproblem(statefunc, stateder, state, (t, Inf), interpolant, modelargs...; modelkwargs...)
    else
        problem = deproblem(statefunc, state, (t, Inf), interpolant, modelargs...; modelkwargs...)
    end
    init(problem, alg, solverargs...; save_everystep=false, dense=true, solverkwargs...)
end

function init_dynamic_system(deproblem, statefunc, state, t, input, modelargs=(), solverargs=(); 
    alg=nothing, stateder=state, modelkwargs=NamedTuple(), solverkwargs=NamedTuple(), numtaps=3)
    trigger = Inpin()
    handshake = Outpin{Bool}()
    integrator = construct_integrator(deproblem, input, statefunc, state, t, modelargs, solverargs; 
            alg=alg, modelkwargs=modelkwargs, solverkwargs=solverkwargs, numtaps=numtaps)
    trigger, handshake, integrator
end
