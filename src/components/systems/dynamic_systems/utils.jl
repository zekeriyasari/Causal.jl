# This file includes utilities for DynamicalSystems module

import ..Systems: hasargs

allstates(x, u, t) = x

function construct_interpolant(input, t)
    if typeof(input) <: Bus
            inputval = rand(datatype(input), length(input))
            interpolant = Interpolant(t, Inf, inputval, inputval)
    else
        interpolant = nothing
    end
    interpolant
end

function construct_integrator(deproblem, input, statefunc, state, t, modelargs=(), solverargs=(); alg=nothing, stateder=state,
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

# struct SignatureError <: Exception
#     msg::String
# end
# Base.showerror(io::IO, ex::SignatureError) = print(io, "SignatureError: " * ex.msg)


# signatures(func) = [method.sig for method in methods(func)]

# function check_methods(model::Symbol, statefunc, outputfunc)
#     if statefunc === nothing
#         if !hasargs(outputfunc, 3)
#             msg = "Expected signature for $model is `outputfunc(x, u, t)`, got $(signatures(outputfunc))"
#             throw(SignatureError(msg))
#         end
#     end
#     if model in [:DiscreteSystem, :ODESystem]
#         if !hasargs(statefunc, 4)
#             msg = "Expected signature for $model is `statefunc(dx, x, u, t)`, got $(signatures(statefunc))"
#             throw(SignatureError(msg))
#         end
#     elseif model == :DAESystem
#         if !hasargs(statefunc, 5)
#             msg = "Expected signature for $model is `statefunc(out, dx, x, u, t)`, got $(signatures(statefunc))"
#             throw(SignatureError(msg))
#         end
#     elseif model == :RODESystem
#         if !hasargs(statefunc, 5)
#             msg = "Expected signature for $model is `statefunc(dx, x, u, t, w)`, got $(signatures(statefunc))"
#             throw(SignatureError(msg))
#         end
#     elseif model == :SDESystem
#         if !(typeof(statefunc) <: Tuple{<:Any, <:Any})
#             msg = "Throw expected type of statefunc for $model is 2-tuple, got $(typeof(statefunc))"
#             throw(SignatureError(msg))
#         end
#         if !hasargs(statefunc[1], 4)
#             msg = "Expected drift signature for $model is `statefunc(dx,x,u,t)`,got $(signatures(statefunc[1]))"
#             throw(SignatureError(msg))
#         end
#         if !hasargs(statefunc[2], 4)
#             msg = "Expected diffusion signature for $model is `statefunc(dx,x,u,t)`, got $(signatures(statefunc[2]))"
#             throw(SignatureError(msg))
#         end
#     elseif model == :DDESystem
#         if !hasargs(statefunc[1], 5)
#             msg = "Expected diffeq signature for $model is `statefunc(dx,x,h,u,t)`,got $(signatures(statefunc[1]))"
#             throw(SignatureError(msg))
#         end
#     end
#     if outputfunc != nothing
#         if !hasargs(outputfunc, 3)
#             msg = "Expected signature for $model is `outputfunc(x, u, t)`, got $(signatures(outputfunc))"
#             throw(SignatureError(msg))
#         end
#     end
# end
