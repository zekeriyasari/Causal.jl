# This file includes macro tools to define new components types

#= 
    Returns true if `ex` is of the form 

```julia 
julia> ex = :(
       struct Foo <: Bar
       x::Int
       end 
       )
```
Note that `Foo` is a subtype of `Bar`.
=#
issubtype(ex::Expr) = (nex = ex.args[2]; nex isa Expr && nex.head == :(<:))

#= 
    Returns true if `ex` is of the form 

```julia 
julia> ex = :(
       struct Foo{T} <: Bar
       x::T
       end 
       )
:(struct Foo{T} <: Bar
      #= REPL[17]:3 =#
      x::T
  end)
```
Note that `Foo` is a parametric type.
=#
isparametric(ex::Expr) = (nex = ex.args[2].args[1]; nex isa Expr && nex.head == :curly)


#= 
   Returns true if `ex` has default values. 

```julia 
ex = :(x::T = 1.)
```
=#
hasdefault(ex::Expr) = ex.head == :(=) 

#=
    Appends the `nex` to `ex`. A mininmum working example: 

```julia 
julia> ex = :(
       struct Foo <: Bar
       x::Int
       end 
       )
:(struct Foo <: Bar
      #= REPL[15]:3 =#
      x::Int
  end)

julia> Causal.Components.ComponentsBase.appendex!(ex, nex)
:(struct Foo{T} <: Bar
      #= REPL[15]:3 =#
      x::Int
      y::T = 1.0
  end)
```
=#
function appendex!(ex::Expr, nex::Expr)
    ex.args[3].head == :block || error("Invalid expression $ex")

    # Append expression 
    push!(ex.args[3].args, nex)
    # field::T
    if nex.head == :(::)
        typesymbol = nex.args[2]
    # field::T = default or field = T
    elseif nex.head == :(=)
        lhs = nex.args[1]
        typesymbol  = 
            # field::T 
            if lhs isa Expr && lhs.head == :(::)
                typesymbol = lhs.args[2] 
            # field 
            elseif lhs isa Symbol
                 typesymbol = lhs 
            else 
                error("Invalid usage.")
            end 
    end
    appendtype!(ex, typesymbol)
    ex
end

function appendtype!(ex::Expr, typesymbol::Symbol)
    if isparametric(ex)
        push!(ex.args[2].args[1].args, typesymbol) 
    else 
        ex.args[2].args[1] = :($(ex.args[2].args[1]){$typesymbol})
    end 
    ex
end

