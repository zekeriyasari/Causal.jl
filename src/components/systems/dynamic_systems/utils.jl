# This file includes utilities for DynamicalSystems module

import ..Systems: hasargs

struct Solver{A, T}
    alg::A 
    params::Dict{Symbol, T}
end
Solver(alg) = Solver(alg, Dict{Symbol, Any}())

mutable struct Noise{P, R}
    process::P 
    prototype::R
    seed::UInt
end
Noise(process) = Noise(process, nothing, UInt(0))

struct Diffusion{M} 
    matrix::M
end
(dif::Diffusion)(dx, x, u, t) = (dx .= dif.matrix)

struct History{F, C, D, O}
    func::F 
    out::O
    conslags::C 
    depslags::D
    neutral::Bool
end
History(func, out) = History(func, out, [], [], false)
(hist::History)(u, t) = hist.func(hist.out, u, t)

struct SignatureError <: Exception
    msg::String
end
Base.showerror(io::IO, ex::SignatureError) = print(io, "SignatureError: " * ex.msg)

signatures(func) = [method.sig for method in methods(func)]

function check_methods(model, statefunc, outputfunc)
    if statefunc == nothing
        if !hasargs(outputfunc, 3)
            msg = "Expected signature for $model is `outputfunc(x, u, t)`, got $(signatures(outputfunc))"
            throw(SignatureError(msg))
        end
    end
    if model in [:DiscreteSystem, :ODESystem]
        if !hasargs(statefunc, 4)
            msg = "Expected signature for $model is `statefunc(dx, x, u, t)`, got $(signatures(statefunc))"
            throw(SignatureError(msg))
        end
    elseif model == :DAESystem
        if !hasargs(statefunc, 5)
            msg = "Expected signature for $model is `statefunc(out, dx, x, u, t)`, got $(signatures(statefunc))"
            throw(SignatureError(msg))
        end
    elseif model == :RODESystem
        if !hasargs(statefunc, 5)
            msg = "Expected signature for $model is `statefunc(dx, x, u, t, w)`, got $(signatures(statefunc))"
            throw(SignatureError(msg))
        end
    elseif model == :SDESystem
        if !(typeof(statefunc) <: Tuple{<:Any, <:Any})
            msg = "Throw expected type of statefunc for $model is 2-tuple, got $(typeof(statefunc))"
            throw(SignatureError(msg))
        end
        if !hasargs(statefunc[1], 4)
            msg = "Expected drift signature for $model is `statefunc(dx,x,u,t)`,got $(signatures(statefunc[1]))"
            throw(SignatureError(msg))
        end
        if !hasargs(statefunc[2], 4)
            msg = "Expected diffusion signature for $model is `statefunc(dx,x,u,t)`, got $(signatures(statefunc[2]))"
            throw(SignatureError(msg))
        end
    elseif model == :DDESystem
        # if typeof(statefunc) <: Tuple{<:Any, <:Any}
        #     msg = "Throw expected type of statefunc for $model is 2-tuple, got $(typeof(statefunc))"
        #     throw(SignatureError(msg))
        # end
        if !hasargs(statefunc[1], 5)
            msg = "Expected diffeq signature for $model is `statefunc(dx,x,h,u,t)`,got $(signatures(statefunc[1]))"
            throw(SignatureError(msg))
        end
        if !hasargs(statefunc[2], 3)
            msg = "Expected diffusion signature for $model is `statefunc(out,u,t)`, got $(signatures(statefunc[2]))"
            throw(SignatureError(msg))
        end
    end
    if outputfunc != nothing
        if !hasargs(outputfunc, 3)
            msg = "Expected signature for $model is `outputfunc(x, u, t)`, got $(signatures(outputfunc))"
            throw(SignatureError(msg))
        end
    end
end