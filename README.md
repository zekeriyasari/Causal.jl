# Jusdl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://zekeriyasari.github.io/Jusdl.jl/)
[![Build Status](https://travis-ci.com/zekeriyasari/Jusdl.jl.svg?branch=master)](https://travis-ci.com/zekeriyasari/Jusdl.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/zekeriyasari/Jusdl.jl?svg=true)](https://ci.appveyor.com/project/zekeriyasari/Jusdl-jl)
[![Codecov](https://codecov.io/gh/zekeriyasari/Jusdl.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/zekeriyasari/Jusdl.jl)
[![Coveralls](https://coveralls.io/repos/github/zekeriyasari/Jusdl.jl/badge.svg?branch=master)](https://coveralls.io/github/zekeriyasari/Jusdl.jl?branch=master)

Jusdl (Julia-Based System Description Language) focusses on effective systems simulations together with online and offline data analysis. In Jusdl, it is possible to simulate discrete time and continuous time, static or dynamical systems. In particular, it is possible to simulate dynamical systems modeled by different types of differential equations such as ODE (Ordinary Differential Equation), Random Ordinary Differential Equation (RODE), SDE (Stochastic Differential Equation), DDE (Delay Differential Equation) and DAE (Differential Algebraic Equation), and discrete difference equations. During the simulation, the data flowing through the links of the model can processed online and specialized analyzes can be performed. These analyzes can also be enriched with plugins that can easily be defined using the standard Julia library or various Julia packages. The simulation is performed by evolving the components of the model individually and in parallel in sampling time intervals. The individual evolution of the components allows the simulation of the models including the components that are represented by different kinds of mathematical equations.

## Features

* Simulation of a large class of systems: 
    * Static systems (whose input, output relation is represented by a functional relation)
    * Dynamical systems (whose input, state and output relation is represented by difference or differential equations[1]).
        * Dynamical systems modelled by continuous time differential equations: ODE, DAE, RODE, SDE, DDE.
        * Dynamics systems modelled by discrete time difference equations.
* Simulation of models consisting of components that are represented by different type mathematical equations.
* Individual construction of components, no need to construct a unique equation representing the whole model.
* Online data analysis through plugins 
* Flexibility to enrich the data analysis scope through used defined plugins.

[1] : [DifferentialEquations.jl](https://docs.juliadiffeq.org/) package is used for differential equation solving.

## A Fist Look 
```julia
# Construct a Model 
gen = SinewaveGenerator(amplitude=1., frequency=1., offset=0.)
adder = Adder(Bus(2), (+, -))
ds = ODESystem(Bus(), Bus(), (dx, x, u, t) -> (dx .= -x), (x, u, t) -> x, [1.], 0.)
memory = Memory(Bus(), 2)
connect(gen.output, adder.input[1])
connect(adder.output, ds.input)
connect(ds.output, memory.input)
connect(memory.output, adder.input[2])
model = Model(gen, adder, ds, memory)

# Simulate the model 
tinit, tsample, tfinal = 0, 0.01, 10
sim = simulate(model, tinit, tsample, tfinal)
```

## Contribution 
Any form of contribution is welcome. Please feel free to open an [issue](https://github.com/zekeriyasari/Jusdl.jl/issues) for bug reports, feature requests, new ideas and suggestions etc., or to send a pull request for any bug fixes.
