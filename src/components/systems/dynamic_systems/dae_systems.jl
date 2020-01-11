# This file includes DAESystems

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractDAESystem

const DAESolver = Solver(IDA())


mutable struct DAESystem{IB, OB, T, H, SF, OF, ST, IV, S, D} <: AbstractDAESystem
    @generic_dynamic_system_fields
    stateder::ST
    diffvars::D
    function DAESystem(input, output, statefunc, outputfunc, state, stateder, t, diffvars; solver=DAESolver)
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver), typeof(diffvars)}(input, output, trigger, Callback[], 
            uuid4(), statefunc, outputfunc, state, inputval, t, solver, stateder, diffvars)
    end
end

show(io::IO, ds::DAESystem) = print(io, "DAESystem(state:$(ds.state), stateder:$(ds.stateder), t:$(ds.t), ", 
    "diffvars:$(checkandshow(ds.diffvars)), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
