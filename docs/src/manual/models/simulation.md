# Simulation 

During the simulation of a `model`, a [`Simulation`](@ref) object is constructed. The field names of the `Simulation` object is 
* `model::Model`: The model for which the `Simulation` is constructed. 
* `path::String`: The path of the directory into which all simulation-related files (log, data files etc.) are saved.
* `logger::AbstractLogger`: The logger of the simulation constructed to log each stage of the `Simulation` . 
* `state::Symbol`: The state of the `Simulation`. The `state` may be `:running` if the simulation is running, `:halted` is the simulation is terminated without being completed, `:done` if it is terminated.
* `retcode::Symbol`: The return code of the simulation. The `retcode` may be `:success` if the simulation is completed without errors, `:failed` if the an error occurs during the simulation. 

## Full API 
```@autodocs
Modules = [Jusdl]
Pages   = ["simulation.jl"]
Order = [:type, :function]
```