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
* Flexibility to enrich the data analysis scope through user-defined plugins.

[1] : [DifferentialEquations.jl](https://docs.juliadiffeq.org/) package is used for differential equation solving.

## Installation
Installation of Jusdl is like any other registered Julia package.  Enter the Pkg REPL by pressing ] from the Julia REPL and then add Jusdl:
```julia
] add Jusdl
```

## A First Look

Consider following simple model.
<center>
    <img src="docs/src/assets/ReadMeModel/brokenloop.svg"
        alt="Closed Loop System"
        style="float: center; margin-right: 10px;"
        width="75%"/>
</center>
Note that the model consists of connected components. In this example, the components are the sinusoidal wave generator, an adder, a dynamical system and a memory. The writer is included in the model to save simulation data. By using Jusdl, the model is simulated as follows:

```julia
using Jusdl
# Construct a Model 
gen = FunctionGenerator(sin)
adder = Adder(Bus(2), (+, -))
ds = ODESystem(Bus(1), Bus(1), (dx,x,u,t) -> (dx[1] = -x[1] + u[1](t)), (x,u,t) -> x, [1.], 0.)
mem = Memory(Bus(1), 1)
writer = Writer(Bus(2)) 
connect(gen.output, adder.input[1])
connect(adder.output, ds.input)
connect(ds.output, mem.input)
connect(mem.output, adder.input[2])
connect(gen.output, writer.input[1])
connect(ds.output, writer.input[2])
model = Model(gen, mem, adder, ds, writer)

# Simualate the model 
tinit, tsample, tfinal = 0, 0.01, 10.
sim = simulate(model, tinit, tsample, tfinal)

# Read and plot data 
t, x = read(writer, flatten=true)
using Plots 
plot(t, x[:, 1], label="r(t)", xlabel="t")
plot!(t, x[:, 2], label="y(t)", xlabel="t")
plot!(t, 6 / 5 * exp.(-2t) + 1 / 5 * (2 * sin.(t) - cos.(t)), label="Analytical Solution")
```
<center>
    <img src="docs/src/assets/ReadMePlot/readme_example.svg"
        alt="Readme Plot"
        style="float: center; margin-right: 10px;"
        width="75%"/>
</center>

For more information about how to use Jusdl, see its [documentation](https://zekeriyasari.github.io/Jusdl.jl/) .

## Contribution 
Any form of contribution is welcome. Please feel free to open an [issue](https://github.com/zekeriyasari/Jusdl.jl/issues) for bug reports, feature requests, new ideas and suggestions etc., or to send a pull request for any bug fixes.
