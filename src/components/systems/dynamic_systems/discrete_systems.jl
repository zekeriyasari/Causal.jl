# This file includes the Discrete Systems

import ....Components.Base: @generic_system_fields, @generic_dynamic_system_fields, AbstractDiscreteSystem

const DiscreteSolver = Solver(FunctionMap())


mutable struct DiscreteSystem{IB, OB, L, SF, OF, ST, T, S} <: AbstractDiscreteSystem
    @generic_dynamic_system_fields
    function DiscreteSystem(input, output, statefunc, outputfunc, state, t;  solver=DiscreteSolver)
        trigger = Link()
        new{typeof(input), typeof(output), typeof(trigger), typeof(statefunc), typeof(outputfunc), typeof(state), 
            typeof(t), typeof(solver)}(input, output, trigger, Callback[], uuid4(), statefunc, outputfunc, state, t, 
            solver)
    end
end

show(io::IO, ds::DiscreteSystem) = print(io, "DiscreteSystem(state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
