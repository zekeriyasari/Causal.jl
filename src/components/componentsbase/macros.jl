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


# function _append_common_fields!(ex, newbody, newparamtypes)
#     # Append body 
#     body = ex.args[3]
#     append!(body.args, newbody.args)

#     # Append struct type parameters
#     name = ex.args[2] 
#     if name isa Expr && name.head === :(<:)
#         name = name.args[1]
#     end

#     if name isa Expr && name.head === :curly 
#         append!(name.args, newparamtypes)
#     elseif name isa Symbol
#         ex.args[2] = Expr(:curly, name, newparamtypes...)  # parametrize ex 
#     end 
# end

# function deftype(ex)
#     # Check ex head
#     ex isa Expr && ex.head == :struct || error("Invalid source defition")

#     # Get struct name
#     name = ex.args[2]
#     if name isa Expr && name.head === :(<:)
#         name = name.args[1]
#     end
    
#     # Process struct body
#     body = ex.args[3]
#     kwargs = Expr(:parameters)
#     callargs = Symbol[]

#     _def!(body, kwargs, callargs)

#     # struct has no fields
#     isempty(kwargs.args) && return quote
#         Base.@__doc__($(esc(ex))) 
#     end

#     if name isa Symbol
#         return quote 
#             Base.@__doc__($(esc(ex)))
#             $(esc(name))($kwargs) = $(esc(name))($(callargs...)) 
#         end
#     elseif name isa Expr && name.head === :curly 
#         _name = name.args[1]
#         _param_types = name.args[2:end]
#         __param_types = [_type_ isa Symbol ? _type_  : _type_.args[1] for _type_ in _param_types]
#         return quote 
#             Base.@__doc__($(esc(ex)))
#             $(esc(_name))($kwargs) = $(esc(_name))($(callargs...))
#             $(esc(_name)){$(esc.(__param_types)...)}($kwargs) where {$(esc.(_param_types)...)} = 
#                 $(esc(_name)){$(esc.(__param_types)...)}($(callargs...))
#         end
#     end
# end

# function _def!(body, kwargs, callargs)
#     for i in 1 : length(body.args)
#         bodyex = body.args[i]
#         if bodyex isa Symbol # var
#             push!(kwargs.args, bodyex)
#             push!(callargs, bodyex)
#         elseif bodyex isa Expr 
#             if bodyex.head === :(=)
#                 rhs = bodyex.args[2]
#                 lhs = bodyex.args[1] 
#                 if lhs isa Expr && lhs.head === :(::) # var::T = 1
#                     var = lhs.args[1] 
#                 elseif lhs isa Symbol # var = 1
#                     var = lhs
#                 elseif lhs isa Expr && lhs.head == :call # inner constructors
#                     continue
#                 end
#                 push!(kwargs.args, Expr(:kw, var, esc(rhs)))
#                 push!(callargs, var)
#                 body.args[i] = lhs 
#             elseif bodyex.head === :(::)  # var::T
#                 var = bodyex.args[1]
#                 push!(kwargs.args, var)
#                 push!(callargs, var)
#             end
#         end
#     end
# end

