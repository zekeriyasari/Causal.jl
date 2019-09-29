# This file includes DDESystems

import ....Components.Base: @generic_dde_system_fields, AbstractDDESystem

const DDESolver = Solver(MethodOfSteps(Tsit5()))

mutable struct DDESystem{SF, OF, ST, T, H, IB, OB, S, L} <: AbstractDDESystem
    @generic_dde_system_fields
    function DDESystem(statefunc, outputfunc, state, history, t, input, output)
        solver = DDESolver
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(history), typeof(input), typeof(output),  typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, history, t, input, output, solver, trigger, Callback[], uuid4())
    end
end

show(io::IO, ds::DDESystem) = print(io, "DDESystem(state:$(ds.state), history:$(ds.history), t:$(ds.t), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)), noise:$(checkandshow(ds.noise)))")

