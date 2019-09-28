# This file includes the Discrete Systems

import ....Components.Base: @generic_discrete_system_fields, AbstractDiscreteSystem

# const DiscreteSolver = Solver(FunctionMap{true}())
const DiscreteSolver = Solver(FunctionMap())  # Caution: There seems some update to use FunctionMap parametrized with false.

mutable struct DiscreteSystem{SF, OF, ST, IB, OB, S, L} <: AbstractDiscreteSystem
    @generic_discrete_system_fields
    function DiscreteSystem(statefunc::SF, outputfunc::OF, state::ST, t::Int, input::IB, output::OB, solver::S, trigger::L, callbacks::Vector{Callback}, id::UUID) where {SF, OF, ST, IB, OB, S, L}
        check_methods(:DiscreteSystem, statefunc, outputfunc)
        new{SF, OF, ST, IB, OB, S, L}(statefunc, outputfunc, state, t, input, output, solver, trigger, callbacks, id)
    end
end
DiscreteSystem(statefunc, outputfunc, state, t, input, output; solver=DiscreteSolver) = 
    DiscreteSystem(statefunc, outputfunc, state, t, input, output, solver, Link(), Callback[], uuid4())

show(io::IO, ds::DiscreteSystem) = print(io, "DiscreteSystem(state:$(ds.state), t:$(ds.t), input:$(checkandshow(ds.input)), output:$(checkandshow(ds.output)))")
