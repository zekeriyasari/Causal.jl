# This file includes the Discrete Systems

import ....Components.Base: @generic_discrete_system_fields, AbstractDiscreteSystem

const DiscreteSolver = Solver(FunctionMap())


mutable struct DiscreteSystem{SF, OF, ST, T, IB, OB, S, L} <: AbstractDiscreteSystem
    @generic_discrete_system_fields
    function DiscreteSystem(statefunc, outputfunc, state, t, input, output)
        solver = DiscreteSolver
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, t, input, output, solver, trigger, Callback[], uuid4())
    end
end

show(io::IO, ds::DiscreteSystem) = print(io, "DiscreteSystem(state:$(ds.state), t:$(ds.t), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
