# This file includes DAESystems

import ....Components.Base: @generic_system_fields, @generic_dynamic_system_fields, AbstractDAESystem

const DAESolver = Solver(IDA())


mutable struct DAESystem{IB, OB, L, SF, OF, ST, T, S, D} <: AbstractDAESystem
    @generic_dynamic_system_fields
    stateder::ST
    diffvars::D
    function DAESystem(statefunc, outputfunc, state, stateder, t, diffvars, input, output)
        solver = DAESolver
        trigger = Link()
        new{typeof(input), typeof(output), typeof(trigger), typeof(statefunc), typeof(outputfunc), typeof(state), 
            typeof(t), typeof(solver), typeof(diffvars)}(input, output, trigger, Callback[], uuid4(), statefunc, 
            outputfunc, state, t, solver, stateder, diffvars)
    end
end

show(io::IO, ds::DAESystem) = print(io, "DAESystem(state:$(ds.state), stateder:$(ds.stateder), t:$(ds.t), ", 
    "diffvars:$(checkandshow(ds.diffvars)), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
