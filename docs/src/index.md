# Jusdl

This is the official documentation of Jusdl that enables fast and effective systems simulations together with online and offline data analysis. In Jusdl, it is possible to simulate discrete time and continuous time, static or dynamical systems. In particular, it is possible to simulate dynamical systems modeled by different types of differential equations such as ODE (Ordinary Differential Equation), Random Ordinary Differential Equation (RODE), SDE (Stochastic Differential Equation), DDE (Delay Differential Equation) and DAE (Differential Algebraic Equation), and discrete difference equations. During the simulation, the data flowing through the links of the model can processed online and offline and specialized analyzes can be performed. These analyzes can also be enriched with plugins that can easily be defined using the standard Julia library or various Julia packages. The simulation is done with the parallel evolution of the model components individually and sampling sampling time intervals. The individual evolution of the components allows the simulation of the models including the components that are represented by different kinds of mathematical equations while the parallel evolution of components increases the simulation speed. 

## Table of Contents

```@contents
Pages = [
    "manual/callback.md"
    ]
```