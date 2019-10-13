# This file includes DDESystems

import ....Components.Base: @generic_system_fields, @generic_dynamic_system_fields, AbstractDDESystem

const DDESolver = Solver(MethodOfSteps(Tsit5()))

mutable struct DDESystem{IB, OB, L, SF, OF, ST, T, S, H} <: AbstractDDESystem
    @generic_dynamic_system_fields
    history::H 
    function DDESystem(input, output, statefunc, outputfunc, state, history, t; solver=DDESolver)
        trigger = Link()
        new{typeof(input), typeof(output), typeof(trigger), typeof(statefunc), typeof(outputfunc), typeof(state), 
            typeof(t), typeof(solver), typeof(history)}(input, output, trigger, Callback[], uuid4(), statefunc,     
            outputfunc, state, t, solver, history)
    end
end

show(io::IO, ds::DDESystem) = print(io, "DDESystem(state:$(ds.state), history:$(ds.history), t:$(ds.t), ", 
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)), noise:$(checkandshow(ds.noise)))")

