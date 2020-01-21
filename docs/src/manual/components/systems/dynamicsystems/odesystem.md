# ODESystem

## Basic Operation of ODESystem 
When an `ODESystem` is triggered, it reads its current time from its `trigger` link, reads its `input`, solves its differential equation and computes its output. Let us observe the basic operation of `ODESystem`s with a simple example. 

We first construct an `ODESystem`. Since an `ODESystem` is represented by its state equation and output equation, we need to define those equations.


## Full API 
```@docs 
ODESystem 
LinearSystem 
LorenzSystem 
ChenSystem
ChuaSystem
RosslerSystem 
VanderpolSystem
```