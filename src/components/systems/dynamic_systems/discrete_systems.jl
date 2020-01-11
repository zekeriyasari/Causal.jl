# This file includes the Discrete Systems

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractDiscreteSystem

const DiscreteSolver = Solver(FunctionMap())


mutable struct DiscreteSystem{IB, OB, T, H, SF, OF, ST, IV, S} <: AbstractDiscreteSystem
    @generic_dynamic_system_fields
    function DiscreteSystem(input, output, statefunc, outputfunc, state, t;  solver=DiscreteSolver)
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state),  typeof(inputval), typeof(solver)}(input, output, trigger, Callback[], uuid4(), statefunc, 
            outputfunc, state, inputval, t, solver)
    end
end

show(io::IO, ds::DiscreteSystem) = print(io, "DiscreteSystem(state:$(ds.state), t:$(ds.t), ",
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
