# DAESystem 



## Basic Operation of DAESystem 
The basic operation of `DAESystem` is the same as [Basic Operation of ODESystem](@ref). The basic opeation of `DAESystem` is given with an example. Consider the following differential algebraic equation.
```math 
    \begin{array}{l}
    dx_1 = -0.04 x_1 + 10^4 x_2 x_3 \\[0.25]
    dx_2 = 0.04 x_1 - 10^4 x_2 x_3  - 3 \times 10^7 x_2^2 \\[0.25]
    1 = x_1 + x_2 + x_3
    \end{array}
```
with the initial conditions ``x_1(0) = 1``, ``x_2(0) = 0``, ``x_3(0) = 0``, ``dx_1(0) = -0.04``, ``dx_2(0) = 0.04``, ``x_3(0) = 0``. In this equation, the variables ``x_1`` and ``x_2`` is the differential variables and the variable ``x_3`` is the algebraic variable.

Since `DAESystem`s are represented by a state function `statefunc` which are *Differential Algebraic Equation* and an output function `outputfunc`, we need to define those functions.
We start with the `statefunc` corresponding to the differential algebraic equation given above. 
```@repl dae_ex 
using Jusdl # hide 
function statefunc(out,dx,x,u,t)
    out[1] = - 0.04x[1]              + 1e4*x[2]*x[3] - dx[1]
    out[2] = + 0.04x[1] - 3e7*x[2]^2 - 1e4*x[2]*x[3] - dx[2]
    out[3] = x[1] + x[2] + x[3] - 1.0
end
```
Note the signature of  `statefunc`. The `statefunc` *modifies* a vector `out` using `dx`, `x`, `u`, and `t`. For this example, we take all the states as outputs, i.e., we have an output function `outputfunc` given as
```@repl dae_ex 
outputfunc(x, u, t) = x
```
Note that `outputfunc`, vector `x` is *generated* but not mutated. We also need to specify the differential variables. 
```@repl dae_ex 
diffvars = [true, true, false]
```
Note that the first two variables are differential variables and the last variable is algebraic variable. From above equation, the system does not any inputs. But, we need a bus as output with three links. 
```@repl dae_ex 
input = nothing 
output = Bus(3)
```



## Full API
```@docs 
DAESystem
```