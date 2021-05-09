# 
# Julia System Desciption Language
# 
module Causal

using UUIDs
using DifferentialEquations
using Sundials
using LightGraphs
using DataStructures
using JLD2
using Plots
using ProgressMeter 
using Logging
using LinearAlgebra
using Dates
using NLsolve
using Interpolations
using LibGit2
using DocStringExtensions
import GraphPlot.gplot
import FileIO: load
import Base: show, display, write, read, close, setproperty!, getproperty,  mv, cp, open,  istaskdone, istaskfailed, 
    getindex, setindex!, size, isempty

include("utilities/utils.jl")
export equip

include("utilities/callback.jl")            
export Callback, 
    enable!, 
    disable!, 
    isenabled, 
    applycallbacks

include("utilities/buffer.jl")
export BufferMode, 
    LinearMode,
    CyclicMode, 
    Buffer, 
    Normal, 
    Cyclic, 
    Fifo, 
    Lifo, 
    write!, 
    isfull, 
    ishit, 
    content, 
    mode, 
    snapshot, 
    datalength, 
    inbuf, 
    outbuf

include("connections/link.jl")
export Link, 
    launch,
    refresh!

include("connections/pin.jl")
export AbstractPin, 
    Outpin, 
    Inpin, 
    connect!, 
    disconnect!, 
    isconnected, 
    isbound

include("connections/port.jl")
export AbstractPort, 
    Inport, 
    Outport, 
    datatype

include("plugins/loadplugins.jl")
export AbstractPlugin, 
    process,
    add, 
    remove, 
    enable, 
    disable, 
    check,
    @def_plugin

include("components/componentsbase/constants.jl")
export TRIGGER_TYPE_SYMBOL, 
    HANDSHAKE_TYPE_SYMBOL, 
    CALLBACKS_TYPE_SYMBOL, 
    ID_TYPE_SYMBOL, 
    MODEL_ARGS_TYPE_SYMBOL, 
    MODEL_KWARGS_TYPE_SYMBOL, 
    SOLVER_ARGS_TYPE_SYMBOL, 
    SOLVER_KWARGS_TYPE_SYMBOL, 
    ALG_TYPE_SYMBOL, 
    INPUT_TYPE_SYMBOL, 
    INTEGRATOR_TYPE_SYMBOL, 
    PLUGIN_TYPE_SYMBOL, 
    TIMEBUF_TYPE_SYMBOL, 
    DATABUF_TYPE_SYMBOL, 
    SINK_CALLBACK_TYPE_SYMBOL

include("components/componentsbase/hierarchy.jl")
export AbstractComponent, 
    AbstractSource, 
    AbstractSystem,
    AbstractSink, 
    AbstractStaticSystem, 
    AbstractDynamicSystem, 
    AbstractSubSystem, 
    AbstractMemory, 
    AbstractDiscreteSystem, 
    AbstractODESystem, 
    AbstractRODESystem, 
    AbstractDAESystem, 
    AbstractSDESystem, 
    AbstractDDESystem

include("components/componentsbase/macros.jl")
include("components/componentsbase/interpolant.jl")
export Interpolant

include("components/componentsbase/takestep.jl")
export readtime!, 
    readstate, 
    readinput!, 
    writeoutput!, 
    computeoutput, 
    evolve!, 
    takestep!, 
    drive!, 
    approve!

include("components/sources/clock.jl")
export Clock, pause!

include("components/sources/generators.jl")
export @def_source,
    FunctionGenerator,
    SinewaveGenerator,
    DampedSinewaveGenerator,
    SquarewaveGenerator,
    TriangularwaveGenerator, 
    ConstantGenerator, 
    RampGenerator, 
    StepGenerator,
    ExponentialGenerator,
    DampedExponentialGenerator

include("components/systems/staticsystems/staticsystems.jl")
export @def_static_system,
    StaticSystem,
    Adder,
    Multiplier, 
    Gain,
    Terminator, 
    Memory, 
    Coupler, 
    Differentiator

include("components/systems/dynamicalsystems/init.jl")

include("components/systems/dynamicalsystems/odesystems.jl")
export @def_ode_system,
    ODESystem,
    ContinuousLinearSystem,
    LorenzSystem, 
    ChenSystem,
    ChuaSystem, 
    RosslerSystem, 
    VanderpolSystem, 
    ForcedLorenzSystem, 
    ForcedChenSystem,
    ForcedChuaSystem,
    ForcedRosslerSystem,
    ForcedVanderpolSystem,
    Integrator

include("components/systems/dynamicalsystems/discretesystems.jl")
export @def_discrete_system,
    DiscreteSystem,
    DiscreteLinearSystem,
    HenonSystem, 
    LoziSystem,
    BogdanovSystem, 
    GingerbreadmanSystem,
    LogisticSystem

include("components/systems/dynamicalsystems/sdesystems.jl")
export @def_sde_system,
    SDESystem, 
    NoisyLorenzSystem, 
    ForcedNoisyLorenzSystem

include("components/systems/dynamicalsystems/daesystems.jl")
export @def_dae_system, 
    DAESystem,
    RobertsonSystem,
    PendulumSystem, 
    RLCSystem

include("components/systems/dynamicalsystems/rodesystems.jl")
export @def_rode_system,
    RODESystem,
    MultiplicativeNoiseLinearSystem

include("components/systems/dynamicalsystems/ddesystems.jl")
export @def_dde_system, 
    DDESystem,
    DelayFeedbackSystem

include("components/sinks/sinks.jl")
export @def_sink,
    Writer, 
    Printer,
    Scope, 
    write!, 
    fwrite!,
    fread,
    update!

include("models/taskmanager.jl")
export TaskManager, 
    checktaskmanager

include("models/simulation.jl")
export Simulation, 
    setlogger, 
    closelogger, 
    report

include("models/model.jl")
export @defmodel,
    Model, 
    inspect!, 
    initialize!, 
    run!, 
    terminate!, 
    simulate!,
    getloops, 
    breakloop!,
    Node, 
    Branch, 
    addnode!, 
    getnode, 
    getcomponent,
    addbranch!,
    getbranch, 
    getlinks,
    deletebranch!, 
    signalflow,
    troubleshoot

end  # module
