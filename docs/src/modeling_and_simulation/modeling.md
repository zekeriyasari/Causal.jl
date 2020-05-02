# Modeling

Jusdl adopts signal-flow approach in modeling systems. Briefly, in the signal-flow approach a model consists of components and connections. The simulation of the model is performed in a clocked simulation environment. That is, the model is not simulated in one shot by solving a huge mathematical equation, but instead is simulated by evolving the components individually and in parallel in different sampling intervals.

The components interact with each other through the connections that are bound to their port. The components are data processing units, and it is the behavior of the component that determines how the data is processed. The component behavior is defined by the mathematical equations obtained as a result of the physical laws that the physical quantities used in the modeling of the component must comply. Depending upon the nature of the system and the modeling, these equations may change, i.e. they may or may not contain derivative terms, or they may contain the continuous time or discrete time variable, etc. The data-flow through the connections is unidirectional, i.e., a component is driven by other components that write data to its input port.

Model simulation is performed by evolving the components individually. To make the components have a common time base, a common clock is used. The clock generates pulses at simulation sampling intervals. These pulses are used to trigger the components during the run stage of the simulation. Each component that is triggered reads its input data from its input port, calculates its output, and writes its output to its output port.

```@raw html
<center>
    <img src="../../assets/Model/model.svg" alt="model" width="50%"/>
</center>
```

## Components 

The component types in Jusdl are shown in the figure below together with output and state equations. The components can be grouped as sources, sinks, and systems. 

The sources are components that generate signals as functions of time. Having been triggered, a source computes its output according to its output function and writes it to its output port. The sources do not have input ports as their outputs depend only on time. 

The sinks are data processing units. Their primary objective is to process the data flowing through the connections of the model online. Having been triggered, a sink reads its input data and processes them, i.e. data can be visualized by being plotted on a graphical user interface, can be observed by being printed on the console, can be stored on data files. The data processing capability of the sinks can be enriched by integrating new plugins that can be developed using the standard Julia library or various available Julia packages. For example, invariants, spectral properties, or statistical information can be derived from the data, parameter estimation can be performed or various signal processing techniques can be applied to the data. Jusdl has been designed to be flexible enough to allow one to enlarge the scope of its available plugins by integrating newly-defined ones.

```@raw html
<center>
    <img src="../../assets/Components/components.svg" alt="model" width="100%"/>
</center>
```

As the output of a static system depends on input and time, a static system is defined by an output equation. Having been triggered, a static system reads its input data, calculates its output, and writes it to its output port. In dynamical systems, however, system behavior is characterized by states and output of a dynamical system depends on input, previous state and time. Therefore, a dynamical system is defined by a state equation and an output equation. When triggered, a dynamical system reads its input, updates its state according to its state equation, calculates its output according to its output equation, and writes its output to its output port. Jusdl is capable of simulating the dynamical systems with state equations in the form of the ordinary differential equation(ODE), differential-algebraic equation(DAE), random ordinary differential equation(RODE), stochastic differential equation(SDE), delay differential equation(DDE) or discrete difference equation. Most of the available simulation environments allow the simulation of systems represented by ordinary differential equations or differential-algebraic equations. Therefore, analyzes such as noise analysis, delay analysis or random change of system parameters cannot be performed in these simulation environments. On the contrary, Jusdl makes it possible for all these analyses to be performed owing to its ability to solve such a wide range of state equations.

## Ports and Connections

A port is actually a bunch of pins to which the connections are bound. There are two types of pins:  an output pin that transfers data from the inside of the component to its outside, and an input pin that transfers data from the outside of component to its inside. Hence, there are two types of ports: an output port that consists of output pins and input port that consists of input pins. 

The data transferred to a port is transferred to its connection(or connections as an output port may drive multiple connections). The data transfer through the connections is performed over the links of the connections. The links are built on top Julia channels.The data written to(read from) a link is written to(read from) the its channel. Active Julia tasks that are bound to channels must exist for data to flow over these channels. Julia tasks are control flow features that allow calculations to be flexibly suspended and maintained without directly communicating the task scheduler of the operating system. Communication and data exchange between the tasks are carried out through Julia channels to which they are bound.

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
            <img src="../../assets/Tasks/reader_task.svg" alt="reader_task" style="width:60%">
        </div>
        <div class="column">
            <img src="../../assets/Tasks/writer_task.svg" alt="writer_task" style="width:60%">
        </div>
        <div class="column">
            <img src="../../assets/Tasks/reader_writer_task.svg" alt="reader_writer_task" style="width:100%">
        </div>
    </div>
</body>
```

In the figure above is shown symbolically the tasks that must be bound to the channel to make a channel readable, writable and both readable and writable. The putter and the taker task is the task that writes data to and reads data from the channel, respectively. To be able to read data from one side of the channel, an active putter task must be bound to the channel at the other side of the channel, and the channel is called a readable channel. Similarly, to be able to write data to one side of the channel, an active taker task must be bound to the channel on the other side, and the channel is called a writable channel. If both active putter and taker tasks are bound to either side of the channel, then the data can both be read from and written to the channel, and the channel is called both readable and writable channel. The data-flow through the channel is only achieved if the channel is both readable and writable channels. The data read from a readable channel is the data written to the channel by the putter task of the channel. If data has not been written yet to the channel by the putter task of the channel during a reading process, then reading does not occur and the putter task is waited to put data to the channel. Similarly, if the data on the channel has not been read yet from the channel by the taker task during a writing process, then the taker task is waited to take data from the channel. 

In the modeling approach adopted, the components reading data from a connection are driven by other components writing data to the connection. Therefore, all of the connections of the model must be both readable and writable connections so that data can flow the connections. This means that all the connections of the model must be connected to a component from both ends. Otherwise, the simulation gets stuck and does not end during a reading process from a channel that is not connected to a component. 