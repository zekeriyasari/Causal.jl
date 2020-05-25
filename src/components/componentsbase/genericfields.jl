# This file contains the generic fields of some types in Components module.

@def generic_component_fields begin 
    trigger::TR
    handshake::HS
    callbacks::CB
    name::Symbol
    id::UUID
end

@def generic_source_fields begin
    # outputfunc::OF
    output::OB
    @generic_component_fields 
end

@def generic_system_fields begin
    input::IB
    output::OB
    @generic_component_fields
end

@def generic_sink_fields begin
    input::IB
    databuf::DB
    timebuf::TB
    plugin::PL
    @generic_component_fields
end

@def generic_static_system_fields begin
    # outputfunc::OF 
    @generic_system_fields
end

@def generic_dynamic_system_fields begin 
    statefunc::SF 
    outputfunc::OF 
    state::ST 
    t::T
    integrator::IN
    @generic_system_fields 
end

