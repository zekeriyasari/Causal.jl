# This file includes RODESystems

import ....Components.Base: @generic_rode_system_fields, AbstractRODESystem

const RODESolver = Solver(RandomEM())
const RODENoise = Noise(WienerProcess(0.,0.))

mutable struct RODESystem{SF, OF, IB, OB, N, S} <: AbstractRODESystem
    @generic_rode_system_fields
    function RODESystem(statefunc, outputfunc, state, t, input, noise, solver)
        check_methods(:RODESystem, statefunc, outputfunc)
        trigger = Link()
        output = outputfunc === nothing ? nothing : Bus(infer_number_of_outputs(outputfunc, state, input, t))  
        new{typeof(statefunc), typeof(outputfunc), typeof(input), typeof(output), typeof(noise), typeof(solver)}(statefunc, outputfunc, state, t, input, output, noise, solver, trigger, Callback[], uuid4())
    end
end
RODESystem(statefunc, outputfunc, state, t=0., input=nothing, noise=Noise(WienerProcess(0., zeros(length(state)))); solver=RODESolver) = 
    RODESystem(statefunc, outputfunc, state, t, input, noise, solver)
