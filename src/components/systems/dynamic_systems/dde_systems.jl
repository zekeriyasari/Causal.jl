# This file includes DDESystems

import ....Components.Base: @generic_dde_system_fields, AbstractDDESystem

const DDESolver = Solver(MethodOfSteps(Tsit5()))

mutable struct DDESystem{SF, OF, H, IB, OB, S} <: AbstractDDESystem
    @generic_dde_system_fields
    function DDESystem(statefunc, outputfunc, state, history, t, input, solver, callbacks, name)
        check_methods(:DDESystem, (statefunc, history.func), outputfunc)
        trigger = Link()
        output = outputfunc == nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(history), typeof(input), typeof(output),  
        typeof(solver)}(statefunc, outputfunc, state, history, t, input, output, solver, trigger, callbacks, name)
    end
end
DDESystem(statefunc, outputfunc, state, history, t=0., input=nothing; solver=DDESolver, callbacks=Callback[], 
    name=string(uuid4())) = DDESystem(statefunc, outputfunc, state, history, t, input, solver, callbacks, name)
