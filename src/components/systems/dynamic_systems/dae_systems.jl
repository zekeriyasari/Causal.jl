# This file includes DAESystems

import ....Components.Base: @generic_dae_system_fields, AbstractDAESystem

const DAESolver = Solver(IDA())


mutable struct DAESystem{SF, OF, ST, T, D, IB, OB, S, L} <: AbstractDAESystem
    @generic_dae_system_fields 
    function DAESystem(statefunc, outputfunc, state, stateder, t, diffvars, input, output)
        solver = DAESolver
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(diffvars), typeof(input), typeof(output), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, stateder, t, diffvars, input, output, solver, trigger, Callback[], uuid4())
    end
end

show(io::IO, ds::DAESystem) = print(io, "DAESystem(state:$(ds.state), stateder:$(ds.stateder), t:$(ds.t), diffvars:$(checkandshow(ds.diffvars)), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
