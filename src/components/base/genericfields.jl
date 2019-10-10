# This file contains the generic fields of some types in Components module.

import ....Jusdl.Utilities: Callback
import ....Jusdl.Connections: Bus, Link


@def generic_source_fields begin
    outputfunc::OF
    output::OB
    trigger::L
    callbacks::Vector{Callback}
    id::UUID
end

@def generic_system_fields begin
    input::IB
    output::OB
    trigger::L
    callbacks::Vector{Callback}
    id::UUID
end

@def generic_sink_fields begin
    input::IB
    databuf::DB
    timebuf::TB
    plugin::P
    trigger::L
    callbacks::Vector{Callback}
    id::UUID
end

@def generic_static_system_fields begin
    @generic_system_fields
    outputfunc::OF 
end

@def generic_dynamic_system_fields begin 
    @generic_system_fields 
    statefunc::SF 
    outputfunc::OF 
    state::ST 
    t::T 
    solver::S
end

# @def generic_discrete_system_fields begin
#     @generic_dynamic_system_fields
# end

# @def generic_ode_system_fields begin
#     @generic_dynamic_system_fields
# end

# @def generic_dae_system_fields begin
#     @generic_dynamic_system_fields
#     stateder::ST
#     diffvars::D
# end

# @def generic_rode_system_fields begin
#     @generic_dynamic_system_fields
#     noise::N
# end

# @def generic_sde_system_fields begin
#     @generic_dynamic_system_fields
#     noise::N
# end

# @def generic_dde_system_fields begin
#     @generic_dynamic_system_fields
#     history::H 
# end

