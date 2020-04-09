# 
# Julia System Desciption Language
# 
module Jusdl

using UUIDs
using DifferentialEquations
using Sundials
using LightGraphs
using MetaGraphs
using DataStructures
using JLD2
using Plots
using Roots
using ProgressMeter 
using Logging
using LinearAlgebra
using Dates
import GraphPlot.gplot
import FileIO: load
import Base: show, display, write, read, close, setproperty!, mv, cp, open, run, istaskdone, istaskfailed, 
    getindex, setindex!, size, isempty

include("utilities/utils.jl")

include("utilities/callback.jl")            
export Callback, enable!, disable!, isenabled, applycallbacks

include("utilities/buffer.jl")
export Buffer, Normal, Cyclic, Fifo, Lifo, write!, isfull, content, mode, snapshot, datalength

include("connections/link.jl")
export Link, launch

include("connections/pin.jl")
export AbstractPin, Outpin, Inpin, connect, disconnect, isconnected, isbound

include("connections/port.jl")
export AbstractPort, Inport, Outport, datatype

include("components/componentsbase/interpolant.jl")
export Interpolant, interpolate

include("components/componentsbase/hierarchy.jl")
export AbstractComponent, AbstractSource, AbstractSystem, AbstractSink, AbstractStaticSystem, 
    AbstractDynamicSystem, AbstractSubSystem, AbstractMemory, AbstractDiscreteSystem, AbstractODESystem, 
    AbstractRODESystem, AbstractDAESystem, AbstractSDESystem, AbstractDDESystem

include("components/componentsbase/genericfields.jl")

include("components/componentsbase/takestep.jl")
export readtime, readstate, readinput, writeoutput, computeoutput, evolve!, takestep, drive, approve

include("components/sources/clock.jl")
export Clock, isrunning, ispaused, isoutoftime, set!, stop!, pause!

include("components/sources/generators.jl")
export FunctionGenerator, SinewaveGenerator, DampedSinewaveGenerator, SquarewaveGenerator, TriangularwaveGenerator, 
    ConstantGenerator, RampGenerator, StepGenerator, ExponentialGenerator, DampedExponentialGenerator

include("components/systems/staticsystems/staticsystems.jl")
export StaticSystem, Adder, Multiplier, Gain, Terminator, Memory, Coupler

include("components/systems/dynamicalsystems/discretesystems.jl")
export DiscreteSystem

include("components/systems/dynamicalsystems/odesystems.jl")
export ODESystem, LinearSystem, LorenzSystem, ChenSystem, ChuaSystem, RosslerSystem, VanderpolSystem

include("components/systems/dynamicalsystems/daesystems.jl")
export DAESystem 

include("components/systems/dynamicalsystems/rodesystems.jl")
export RODESystem 

include("components/systems/dynamicalsystems/sdesystems.jl")
export SDESystem

include("components/systems/dynamicalsystems/ddesystems.jl")
export DDESystem

include("components/systems/subsystems/subsystem.jl")
export SubSystem

include("components/systems/subsystems/network.jl")
export SubSystem, Network, cgsconnectivity, clusterconnectivity, coupling, gplot, topology, nodes, numnodes, dimnodes, 
    deletelink, changeweight, maketimevarying

include("components/sinks/manageplugins.jl")
export fasten, unfasten

include("components/sinks/writer.jl")
export Writer, write!, fwrite, fread, flatten

include("components/sinks/printer.jl")
export Printer

include("components/sinks/scope.jl")
export Scope

include("models/taskmanager.jl")
export TaskManager, checktaskmanager

include("models/simulation.jl")
export Simulation, SimulationError, setlogger, closelogger, report

include("models/model.jl")
export Model, getloops, hasloops, breakloop, inspect, initialize, run, terminate, simulate
export Node, Edge, addnode, addedge

end  # module
