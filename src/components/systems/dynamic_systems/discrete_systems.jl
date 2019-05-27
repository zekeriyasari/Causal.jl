# This file includes the Discrete Systems

import ....Components.Base: @generic_discrete_system_fields, AbstractDiscreteSystem

# const DiscreteSolver = Solver(FunctionMap{true}())
const DiscreteSolver = Solver(FunctionMap())  # Caution: There seems some update to use FunctionMap parametrized with false.

mutable struct DiscreteSystem{SF, OF, IB, OB, S} <:AbstractDiscreteSystem
    @generic_discrete_system_fields
    function DiscreteSystem(statefunc, outputfunc, state, t, input, solver,  callbacks, name)
        check_methods(:DiscreteSystem, statefunc, outputfunc)
        trigger = Link()
        output = outputfunc == nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(solver)}(statefunc, outputfunc,
        state, t, input, output, solver, trigger, callbacks, name)
    end
end
DiscreteSystem(statefunc, outputfunc, state, t=0, input=nothing; solver=DiscreteSolver, callbacks=Callback[], 
    name=string(uuid4())) = DiscreteSystem(statefunc, outputfunc, state, t, input, solver, callbacks, name)
