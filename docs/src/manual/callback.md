# Callback

```@meta
DocTestSetup  = quote
    using Jusdl
end
```

`Callback`s are used to monitor the existence of a specific events and if that specific event occurs, some other special jobs are invoked. `Callback`s are intended to provide additional monitoring capability to any user-defined composite types. As such, `Callback`s are *generaly* fields of user defined composite types objects. When a `Callback` is called, if the `Callback` is enabled and its `condition` function returns true, then its `action` function is invoked. 

## Callback Construction 

```@docs
Callback
```

## Callback Control
A  `Callback` can be controlled, i.e., activated and deactivated.
```@docs 
enable!
disable!
```

## A Simple Example 

Let's define a test object first that has a field named `x` of type `Int` and named `callback` of type `Callback`. 
```julia
julia> mutable struct TestObject
       x::Int
       callback::Callback
       end
```
To construct an instance of `TestObject`, we need to construct a `Callback`. For that purpose, `condition` and `action` function must be defined. For this example, `condition` checks whether the `x` field is positive, and `action` prints a simple message saying that the `x` field is positive.
```julia
julia> condition(testobject) = testobject.x > 0 
condition (generic function with 1 method)

julia> action(testobject) = println("testobject.x is greater than zero") 
action (generic function with 1 method)
```
Now a test object can be constructed
```julia
julia> testobject = TestObject(-1, Callback(condition, action))  
TestObject(-1, Callback{typeof(condition),typeof(action)}(condition, action, true, "dac6f9eb-6daa-4622-a8fa-623f0f88780c"))
```
If the callback is called, no action is performed since the `condition` function returns false. Note the argument sent to the callback. The instance of the `TestObject` to which the callback is a bound.
```julia
julia> testobject.callback(testobject) 
```
Now mutate the test object so that `condition` returns true.
```julia
julia> testobject.x = 3   
3
```
Now, if the callback is called, since the `condition` returns true and the callback is `enabled`, the `action` is invoked.
```julia
julia> testobject.callback(testobject) 
testobject.x is greater than zero
```