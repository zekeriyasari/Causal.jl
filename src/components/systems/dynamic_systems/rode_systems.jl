# This file includes RODESystems

import ....Components.Base: @generic_rode_system_fields, AbstractRODESystem

const RODESolver = Solver(RandomEM())
const RODENoise = Noise(WienerProcess(0.,0.))


mutable struct RODESystem{SF, OF, ST, T, IB, OB, N, S, L} <: AbstractRODESystem
    @generic_rode_system_fields
    function RODESystem(statefunc, outputfunc, state, t, input, output, noise)
        solver = RODESolver
        trigger = Link()
        new{typeof(statefunc), typeof(outputfunc), typeof(state), typeof(t), typeof(input), typeof(output), typeof(noise), typeof(solver), typeof(trigger)}(statefunc, outputfunc, state, t, input, output, noise, solver, trigger, Callback[], uuid4())
    end
end

show(io::IO, ds::RODESystem) = print(io, "RODESystem(state:$(ds.state), t:$(ds.t), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)), noise:$(checkandshow(ds.noise)))")

