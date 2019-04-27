# This file inludes the dynamic system inference.


struct SystemTypeCouldNotInferredError <: Exception
    msg::String
end
Base.showerror(io::IO, ex::SystemTypeCouldNotInferredError) = print(io, "SystemTypeCouldNotInferredError: " * ex.msg)


function DynamicSystem(statefunc, outputfunc, state, t; kwargs...)
    _keys = keys(kwargs)
    if typeof(statefunc) <: Tuple
        if (:noise in _keys || :noise_kwargs in _keys || :seed in _keys)
            try
                check_methods(:SDESystem, statefunc, outputfunc)
                SDESystem(statefunc, outputfunc, state, t; kwargs...)
            catch exc
                msg = "`statefunc` is tuple and arguments include one or more of `noise`, `noise_prototype` or `seed`"
                msg *= "This indicates that the model should be `SDESystem` "
                msg *=  "But function signature is not as expected."
                msg *= exc.msg
                throw(SystemTypeCouldNotInferredError(msg))
            end
        elseif (:constant_lags in _keys || :dependent_lags in _keys || :neutral in _keys)
            try 
                check_methods(:DDESystem, statefunc, outputfunc)
                DDESystem(statefunc, outputfunc, state, t; kwargs...)
            catch exc
                msg = "`statefunc` is tuple and arguments include one or more of `constant_lags`, `dependent_lags` "
                msg *= "or `neutral`. This indicates that the model should be `DDESystem`. " 
                msg *= "But function signature is not as expected. "
                msg *= exc.msg
                throw(SystemTypeCouldNotInferredError(msg))
            end
        else
            msg = "`statefunc` is tuple. This indicates that the model should be either `SDESystem` or `DDESystem` "
            msg *= "But system model could not be inferred from the given arguments. "
            throw(SystemTypeCouldNotInferredError(msg))
        end
    else
        if typeof(t) <: Int
            try
                check_methods(:DiscreteSystem, statefunc, outputfunc)
                DiscreteSystem(statefunc, outputfunc, state, t; kwargs...)
            catch exc
                msg = "Time `t` of Int. This indicates that the model should be `DiscreteSystem`. "
                msg *= "But function signature is not as expected. "
                msg *= exc.msg
                throw(SystemTypeCouldNotInferredError(msg)) 
            end
        elseif typeof(t) <: AbstractFloat
            if (:noise in _keys || :noise_prototype in _keys || :seed in _keys)
                try 
                    check_methods(:RODESystem, statefunc, outputfunc)
                    RODESystem(statefunc, outputfunc, state, t; kwargs...)
                catch exc
                    msg = "Time `t` is of Float64 and arguments include one or more of `noise`, `noise_prototype` or "
                    msg *= "`seed` . This indicates that the model should be `RODEystem`. "
                    msg *= "But function signature is not as expected. "
                    msg *= exc.msg
                    throw(SystemTypeCouldNotInferredError(msg)) 
                end
            elseif (:state_der in _keys || :differential_vars in _keys)
                try 
                    check_methods(:DAESystem)
                    DAESystem(statefunc, outputfunc, state, t; kwargs...)
                catch exc
                    msg = "Time `t` is of Float64 and arguments include one or more of `state_der` or  "
                    msg *= "`differential_vars`. This indicates that the model should be `DAESystem`. "
                    msg *= "But function signature is not as expected. "
                    msg *= exc.msg
                    throw(SystemTypeCouldNotInferredError(msg)) 
                end
            elseif hasargs(statefunc, 4)
                try
                    check_methods(:ODESystem, statefunc, outputfunc)
                    ODESystem(statefunc, outputfunc, state, t; kwargs...)
                catch exc
                    msg = "Time `t` of Float64. This indicates that the model should be `ODEystem`. "
                    msg *= "But function signature is not as expected. "
                    msg *= exc.msg
                    throw(SystemTypeCouldNotInferredError(msg)) 
                end
            else
                msg = "Time `t` is of Float64 This indicates that the model should be one of `DiscreteSystem`, "
                msg *= "`ODESystem`, `DAESystem` or `RODESystem` " 
                msg *= "But system model could not be inferred"
                throw(SystemTypeCouldNotInferredError(msg)) 
            end
        else
            msg = "Expected type for time `t` is `Int` of `Float64`, got $(typeof(t))"
            msg *= "System model could not be inferred"
            throw(SystemTypeCouldNotInferredError(msg))
        end
    end
end
