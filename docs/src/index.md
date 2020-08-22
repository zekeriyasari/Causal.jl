# Causal

Causal enables fast and effective systems simulations together with online and offline data analysis. In Causal, it is possible to simulate discrete-time and continuous-time, static or dynamical systems. In particular, it is possible to simulate dynamical systems modeled by different types of differential equations such as ODE (Ordinary Differential Equation), Random Ordinary Differential Equation (RODE), SDE (Stochastic Differential Equation), DDE (Delay Differential Equation) and DAE (Differential Algebraic Equation), and discrete difference equations. During the simulation, the data flowing through the links of the model can be processed online and offline and specialized analyzes can be performed. These analyses can also be enriched with plugins that can easily be defined using the standard Julia library or various Julia packages. The simulation is performed by evolving the components individually and in parallel during sampling time intervals. The individual evolution of the components allows the simulation of the models that include components represented by different kinds of mathematical equations.

## Installation 

Installation of `Causal` is the similar to any other registered Julia package. Start a Julia session and type 
```julia
] add Causal
```
