# This file includes DAESystems

import ....Components.Base: @generic_dae_system_fields, AbstractDAESystem

const DAESolver = Solver(IDA())


mutable struct DAESystem{SF, OF, D, IB, OB, S} <: AbstractDAESystem
    @generic_dae_system_fields 
    function DAESystem(statefunc, outputfunc, state, stateder, t, diffvars, input, solver)
        check_methods(:DAESystem, statefunc, outputfunc)
        trigger = Link()
        output = outputfunc === nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(diffvars), typeof(input), typeof(output), 
        typeof(solver)}(statefunc, outputfunc, state, stateder, t, diffvars, input, output, solver, trigger, Callback[], uuid4())
    end
end
DAESystem(statefunc, outputfunc, state, stateder=state, t=0., diffvars=nothing, input=nothing; solver=DAESolver) = 
    DAESystem(statefunc, outputfunc, state, stateder, t, diffvars, input, solver)
