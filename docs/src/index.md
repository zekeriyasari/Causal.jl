# Jusdl

This is the official documentation of Jusdl that enables fast and effective systems simulations together with online and offline data analysis. In Jusdl, it is possible to simulate discrete time and continuous time, static or dynamical systems. In particular, it is possible to simulate dynamical systems modeled by different types of differential equations such as ODE (Ordinary Differential Equation), Random Ordinary Differential Equation (RODE), SDE (Stochastic Differential Equation), DDE (Delay Differential Equation) and DAE (Differential Algebraic Equation), and discrete difference equations. During the simulation, the data flowing through the links of the model can processed online and offline and specialized analyzes can be performed. These analyzes can also be enriched with plugins that can easily be defined using the standard Julia library or various Julia packages. The simulation is done with the parallel evolution of the model components individually and sampling sampling time intervals. The individual evolution of the components allows the simulation of the models including the components that are represented by different kinds of mathematical equations while the parallel evolution of components increases the simulation speed. 

## Installation 

Installation of `Jusdl` is the similar to any Julia package. Just add from the repository [https://imel.eee.deu.edu.tr/git/JuSDL.jl.git]. Start a Julia session and type,

```julia
using Pkg 
Pkg.add(PackageSpec(url="https://imel.eee.deu.edu.tr/git/JuSDL.jl.git"))
```

## Modelling and Simulation in Jusdl 

`Jusdl` adopts *signal-flow* approach in modelling systems. Briefly, in signal-flow approach models consists of components and connections. Simulation of the models is performed in a *clocked* simulation environment. That is, the models are simulated in one shot by solving huge mathematical equation, but are simulated by *evolving* components individually and in parallel in different sampling intervals.

### Modelling
There exist different approaches in modeling of systems such as process-based, physical- interaction and signal-flow. Signal flow approach is the one that is used in JuSDL. In this approach, a model comprises of components and busses. Links connect the components to each other. The components are data processing units and it is the behavior of the component that determines how the data is processed. The component behavior is defined by the mathematical equations obtained as a result of the physical laws that the physical quantities used in the modeling of the component must comply. Depending upon the nature of the system and the modeling, these equations may change, i.e. they may or may not contain derivative terms, or they may contain the continuous time or discrete time variable, etc. The components interact themselves through their input-output busses. The data-flow through the busses is unidirectional, i.e., a component is driven by other components that write data to its input bus.

Model simulation is performed by evolving the components individually. To make the components have a common time base, a common time reference is used. The time reference generates pulses at simulation sampling intervals and writes these pulses to the trigger links of the components to trigger them. Each component that is triggered read its input data from its input bus, calculates its output according to its output model and writes it to its output bus.

```@raw html
<center>
    <img src="assets/Model/model.png" alt="model" width="50%"/>
</center>
```

#### Components 

The component types in JuSDL are shown in Figure 2.2 together with output and state equations. The components can be grouped as sources, sinks, and systems. The sources are components that generate signals as functions of time. Having been triggered, a source computes its output according to its output function and writes it to its output bus. The sources do not have input busses as their outputs depend only on time. The sinks are data processing units. Their primary objectives are to process the data flowing through the busses of the model online. Having been triggered, a sink reads its input data and process them, i.e. data can be visualized by being plotted on the graphical user interface, can be observed by being printed on the console, can be stored on data files. The data processing capability of the sinks can be enriched by integrating new plugins that can be developed using the standard Julia library or various available Julia packages. For example, invariants, spectral properties or statistical information can be derived from the data, parameter estimation can be performed or various signal processing techniques can be applied on the data. JuSDL has been designed to be flexible enough to allow one to enlarge the scope of its available plugins by integrating newly-defined ones.

```@raw html
<center>
    <img src="assets/Components/components.png" alt="model" width="100%"/>
</center>
```

As the output of a static system depends on input and time, a static system is defined by an output equation. Having been triggered, a static system reads its input data, calculates its output according to its output function and writes it to its output bus. In dynamic systems, however, system behavior is characterized by states and output of a dynamic system depends on input, previous state and time. Therefore, a dynamic system is defined by a state equation and an output equation. When triggered, a dynamic system reads its input, update its state according to its state equation, calculates its output according to its output equation and writes its output to its output bus. JuSDL is capable of simulating the dynamic systems with state equations in the form of the ordinary differential equation(ODE), differential algebraic equation(DAE), random ordinary differential equation(RODE), stochastic differential equation(SDE), delay differential equation(DDE) or discrete difference equation. Most of the available simulation environments allow the simulation of systems represented by ordinary differential equations or differential algebraic equations. Therefore, analyzes such as noise analysis, delay analysis or random change of system parameters cannot be performed in these simulation environments. On the contrary, JuSDL makes it possible for all these analyses to be performed owing to its ability to solve such a wide range of state equations.

#### Busses 

Busses consist of bunches of links. Links are built upon channels that are defined in standard Julia library. The data written to(read from) the busses is written to(read from) the links which are then written to(read from) the channels. Active Julia tasks that are bound to channels must exist for data to flow over these channels. Ju- lia tasks are control flow features that allow calculations to be flexibly suspended and maintained without directly communicating the task scheduler of the operating system. Communication and data exchange between the tasks are carried out through Julia channels to which they are bound. 

```@raw html
<head>
    <style>
    * {
    box-sizing: border-box;
    }

    .column {
    float: left;
    width: 33.33%;
    padding: 5px;
    }

    /* Clearfix (clear floats) */
    .row::after {
    content: "";
    clear: both;
    display: table;
    }

    /* Responsive layout - makes the three columns stack on top of each other instead of next to each other */
    @media screen and (max-width: 500px) {
    .column {
        width: 100%;
    }
    }
    </style>
</head>

<body>
    <div class="row">
        <div class="column">
            <img src="assets/Tasks/reader_task.png" alt="reader_task" style="width:60%">
        </div>
        <div class="column">
            <img src="assets/Tasks/writer_task.png" alt="writer_task" style="width:60%">
        </div>
        <div class="column">
            <img src="assets/Tasks/reader_writer_task.png" alt="reader_writer_task" style="width:100%">
        </div>
    </div>
</body>
```

In the figure above are shown symbolically the tasks that must be bound to the channel to make a channel readable, writable and both readable and writable. The putter and the taker task is the task that writes data to and reads data from the channel, respectively. To be able to read data from one side of the channel, an active putter task must be bound to the chan- nel at the other side of the channel, and the channel is called a readable channel. Similarly, to be able to write data to one side of the channel, an active taker task must be bound to the channel at the other side, and the channel is called a writable channel. If both active putter and taker tasks are bound to either side of the channel, then the data can both be read from and written to the channel, and the channel is called a both readable and writable channel. The data-flow through the channel is only achieved if the channel is both readable and writable channel. The data read from a readable channel is the data written to the channel by the putter task of the channel. If data has not been written yet to the channel by the putter task of the channel during a reading process, then reading does not occur and the putter task is waited to put data to the channel. Similarly, if the data on the channel has not been read yet from the channel by the taker task during a writing process, then the taker task is waited to take data from the channel. In the modeling approach adopted, the components reading data from a bus are driven by other components writing data to the bus. Therefore, all of the busses of the model must be both readable and writable busses so that data can flow the busses. This means that all the busses of the model must be connected to a component from both ends. Otherwise, the simulation gets stuck and does not end during a reading process from a channel that is not connected to a component. During the simulation, the busses can be arranged as desired, the gain of the busses can be changed, new busses can be added or an existing bus can be broken. In other words, the structure of the system being simulated can change dynamically. This allows one to perform topological studies such as the investigation of the effects of change in the topology of a network or the change o coupling strengths on the behavior of the network.

### Simulation 

A model to be simulated consists of components connected to each other and a time reference. The time reference is used to sample the continuous time signals flowing through the busses of the model and to trigger the components. The simulation is performed by triggering the components with pulses generated by the time reference at simulation sampling time intervals. Having been triggered, the components evolve themselves, compute their outputs and writes them to their output busses.

```@raw html
<center>
    <img src="assets/FlowChart/flowchart.png" alt="model" width="75%"/>
</center>
```

Simulation stages are shown in the flowchart in Figure above. In the first stage, the model is inspected in terms of whether it has unterminated bussed, etc. In case an unterminated bus is inspected, then the simulation is terminated directly. It is also possible to enlarge the scope of the inspection stage to determine whether the model includes algebraic loops, etc.

If the inspection stage results positive, the initialization stage comes next. In this stage, the tasks required for the busses of the model to be both readable and writable are activated and bound to the busses. To this end, a putter and a taker task are activated and bound to both sides of each bus. For example, in Figure 2.5a is shown a part of a model consisting of the components B1, B2, B3, B4 and busses L1, L2, L3. When triggered, B1(B2) reads data from L1(L2) and writes data to L2(L3). The tasks that are bound on L1 and L2 are shown symbolically in Figure 2.5b. A taker and a putter task are bound to L1 and L2, respectively, corresponding to B1. Similarly, a taker and a putter task are bound to L2 and L3, respectively, corresponding to B2. As a putter task and a taker task is bound to L2, data-flow from B1 to B2 is possible through it.

The run stage follows the initialization stage. The tasks activated in initialization stage wait for the components to be triggered by the model time reference. During the run stage, time reference triggers the components by writing pulses that are generated in the intervals of the sampling period of the simulation to their trigger links. The job defined in a task is to read input data from its input bus, to calculate its next state—if any—and output, and to write its output to its output bus. The run stage starts at the initial time of the time reference and continues until the end time of the time reference.

After the run stage, the tasks opened in the initialization stage are closed and the simulation is terminated.

In some simulation environments, a unified mathematical equation represent- ing the model as a whole is obtained and solved in just a single shot for the entire simulation duration, even if the model is thought to consist of components[13]. In JuSDL, a model is, again, thought to consist of components, but is not represented by a unified mathematical equation. Instead, the model is evolved by evolving the components individually by solving their own mathematical equations. The components do not evolve in one shot, but instead, they evolve in parallel for during the time intervals between subsequent sampling instants. Here, it worths noting that the type of the mathematical equations of the components of a model does not have to be the same. Thus, JuSDL allows the simulation of the models consisting of components represented by different types of mathematical equations.

## Table of Contents
```@contents
Pages = [
    "manual/utilities/callback.md"
    "manual/utilities/buffers.md"
    ]
```

```@contents
Pages = [
    "manual/connections/link.md",
    "manual/connections/bus.md"
    ]
```

```@contents
Pages = [
    "manual/components/sources/clock.md",
    "manual/components/sources/generators.md",
    ]
```

## Index

```@index
```