# Task Manager

A [`TaskManager`](@ref) is actually the pairs of components and the tasks constructed corresponding to those components. In `Causal`, models are simulated by individually evolving the components. This individual evolution of components is performed by defining components individually and constructing tasks for each components. The jobs that are defined in these tasks are defined to make the components evolve by reading its time, input, compute its output. During this evolution, the tasks may fail because any inconsistency. Right after the failure of a task, its not possible for the component corresponding to the task to evolve any more. As the data flows through the components that connects the components, model simulation gets stuck. To keep track of the task launched for each component, a `TaskManager` is used. Before starting to simulate a model, a `TaskManager` is constructed for the model components. During the initialization of simulation, tasks corresponding to the components of the model is launched and the pair of component and component task is recorded in the `TaskManager` of the model. During the run stage of the simulation, `TaskManager` keeps track of the component tasks. In case any failure in components tasks, the cause of the failure can be investigated with `TaskManager`.

## Full API 
```@autodocs
Modules = [Causal]
Pages   = ["taskmanager.jl"]
Order = [:type, :function]
```
