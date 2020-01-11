# This file includes DDESystems

import ....Components.ComponentsBase: @generic_system_fields, @generic_dynamic_system_fields, AbstractDDESystem

const DDESolver = Solver(MethodOfSteps(Tsit5()))

mutable struct DDESystem{IB, OB, T, H, SF, OF, ST, IV, S, HST} <: AbstractDDESystem
    @generic_dynamic_system_fields
    history::HST
    function DDESystem(input, output, statefunc, outputfunc, state, history, t; solver=DDESolver)
        trigger = Link()
        handshake = Link{Bool}()
        inputval = typeof(input) <: Bus ? rand(eltype(state), length(input)) : nothing
        new{typeof(input), typeof(output), typeof(trigger), typeof(handshake), typeof(statefunc), typeof(outputfunc), 
            typeof(state), typeof(inputval), typeof(solver), typeof(history)}(input, output, trigger, Callback[], 
            uuid4(), statefunc, outputfunc, state, inputval, t, solver, history)
    end
end

show(io::IO, ds::DDESystem) = print(io, "DDESystem(state:$(ds.state), history:$(ds.history), t:$(ds.t), ", 
    "input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)), noise:$(checkandshow(ds.noise)))")

