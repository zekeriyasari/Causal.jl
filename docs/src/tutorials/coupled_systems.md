# Coupled Systems 

Consider two coupled [`LorenzSystem`](@ref)s. The first system evolves by
```math
\begin{array}{l}
    \dot{x}_{1,1} = \sigma (x_{1,2} - x_{1,1}) + \epsilon (x_{2,1} - x_{1,1})  \\[0.25cm]
    \dot{x}_{1,2} = x_{1,1} (\rho - x_{1,3}) - x_{1,2} \\[0.25cm]
    \dot{x}_{1,3} = x_{1,1} x_{1,2} - \beta x_{1,3}
\end{array}
```
and the second one evolves by
```math
\begin{array}{l}
    \dot{x}_{2,1} = \sigma (x_{2,2} - x_{2,1}) + \epsilon (x_{1,1} - x_{2,1}) \\[0.25cm]
    \dot{x}_{2,2} = x_{2,1} (\rho - x_{2,3}) - x_{2,2} \\[0.25cm]
    \dot{x}_{2,3} = x_{2,1} x_{2,2} - \beta x_{2,3} 
\end{array}
```
where ``x_1 = [x_{1,1}, x_{1,2}, x_{1,3}]``, ``x_2 = [x_{2,1}, x_{2,2}, x_{2,3}]`` are the state vectors of the first and second system, respectively. The coupled system can be written more compactly as, 
```math
\begin{array}{l}
    \dot{X} = F(X) + \epsilon (A ⊗ P) X 
\end{array}
```
where ``X = [x_{1}, x_{2}]``, ``F(X) = [f(x_{1}), f(x_{2})]``,
```math
    A = \begin{bmatrix}
            -1 & 1 \\
            1 & -1 \\
        \end{bmatrix}
```
```math
    P = \begin{bmatrix}
            1 & 0 & 0 \\
            0 & 0 & 0 \\
            0 & 0 & 0 \\
        \end{bmatrix}
```
and ``f`` is the Lorenz dynamics given by 
```math
\begin{array}{l}
    \dot{x}_1 = \sigma (x_2 - x_1) \\[0.25cm]
    \dot{x}_2 = x_1 (\rho - x_3) - x_2 \\[0.25cm]
    \dot{x}_3 = x_1 x_2 - \beta x_3
\end{array}
```

The script below constructs and simulates the model
```@example coupled_system
using Jusdl 

# Describe the model
ε = 10.
@defmodel model begin 
    @nodes begin
        ds1 = ForcedLorenzSystem()
        ds2 = ForcedLorenzSystem()
        coupler = Coupler(conmat=ε*[-1 1; 1 -1], cplmat=[1 0 0; 0 0 0; 0 0 0])
        writer = Writer(input=Inport(6))
    end
    @branches begin 
        ds1[1:3] => coupler[1:3]
        ds2[1:3] => coupler[4:6]
        coupler[1:3] => ds1[1:3]
        coupler[4:6] => ds2[1:3]
        ds1[1:3] => writer[1:3]
        ds2[1:3] => writer[4:6]
    end
end
nothing # hide 
```
To construct the model, we added `ds1` and `ds2` each of which has input ports of length 3 and output port of length 3. To couple them together, we constructed a `coupler` which has input port of length 6 and output port of length 6. The output port of `ds1` is connected to the first 3 pins of `coupler` input port,  and the output of `ds2` is connected to last 3 pins of `coupler` input port. Then, the first 3 pins of `coupler` output is connected to the input port of `ds1` and last 3 pins of `coupler` output is connected to the input port of `ds2`. The block diagram of the model is given below.

```@raw html
<center>
    <img src="../../assets/CoupledSystem/coupledsystem.svg" alt="model" width="60%"/>
</center>
``` 

The the signal-flow graph of the model has 4 directed branches and each of these branches has 3 links. 

It also worths pointing out that the model has two algebraic loops. The first loop consists of `ds1` and `coupler`, and the second loop consists of `ds2` and `coupler`. During the simulation these loops are broken automatically without requiring any user intervention.

The model is ready for simulation. The code block below simulates the model and plots the simulation data.
```@example coupled_system
using Plots

# Simulation settings.
ti, dt, tf = 0, 0.01, 100.

# Simulate the model 
simulate!(model, withbar=false)

# Read simulation data 
t, x = read(getnode(model, :writer).component)

# Compute errors
err = x[:, 1] - x[:, 4]

# Plot the results.
p1 = plot(x[:, 1], x[:, 2], label="ds1")
p2 = plot(x[:, 4], x[:, 5], label="ds2")
p3 = plot(t, err, label="err")
plot(p1, p2, p3, layout=(3, 1))
savefig("coupled_systems_plot.svg"); nothing # hide
```
![](coupled_systems_plot.svg)
