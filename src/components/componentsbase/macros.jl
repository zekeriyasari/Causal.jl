# This file contains the Base module of Plugins module.

# Type hierarchy
abstract type AbstractComponent end
abstract type AbstractSource <: AbstractComponent end
abstract type AbstractSystem <: AbstractComponent end
abstract type AbstractSink <: AbstractComponent end 

abstract type AbstractStaticSystem <: AbstractSystem end
abstract type AbstractDynamicSystem <: AbstractSystem end
abstract type AbstractSubSystem <: AbstractSystem end
abstract type AbstractMemory <: AbstractStaticSystem end
abstract type AbstractDiscreteSystem <: AbstractDynamicSystem end
abstract type AbstractODESystem <: AbstractDynamicSystem end
abstract type AbstractRODESystem <: AbstractDynamicSystem end
abstract type AbstractDAESystem <: AbstractDynamicSystem end
abstract type AbstractSDESystem <: AbstractDynamicSystem end
abstract type AbstractDDESystem <: AbstractDynamicSystem end

#####
##### Component defition syntax.
#####
function _append_commond_fields!(ex, newbody, newparamtypes)
    # Append body 
    body = ex.args[3]
    append!(body.args, newbody.args)

    # Append struct type parameters
    name = ex.args[2] 
    if name isa Expr && name.head === :(<:)
        name = name.args[1]
    end

    if name isa Expr && name.head === :curly 
        append!(name.args, newparamtypes)
    elseif name isa Symbol
        ex.args[2] = Expr(:curly, name, newparamtypes...)  # parametrize ex 
    end 
end

function def(ex)
    # Check ex head
    ex isa Expr && ex.head == :struct || error("Invalid source defition")

    # Get struct name
    name = ex.args[2]
    if name isa Expr && name.head === :(<:)
        name = name.args[1]
    end
    
    # Process struct body
    body = ex.args[3]
    kwargs = Expr(:parameters)
    callargs = Symbol[]

    _def!(body, kwargs, callargs)

    # struct has no fields
    isempty(kwargs.args) && return quote
        Base.@__doc__($(esc(ex))) 
    end

    if name isa Symbol
        return quote 
            Base.@__doc__($(esc(ex)))
            $(esc(name))($kwargs) = $(esc(name))($(callargs...)) 
        end
    elseif name isa Expr && name.head === :curly 
        _name = name.args[1]
        _param_types = name.args[2:end]
        __param_types = [_type_ isa Symbol ? _type_  : _type_.args[1] for _type_ in _param_types]
        return quote 
            Base.@__doc__($(esc(ex)))
            $(esc(_name))($kwargs) = $(esc(_name))($(callargs...))
            $(esc(_name)){$(esc.(__param_types)...)}($kwargs) where {$(esc.(_param_types)...)} = 
                $(esc(_name)){$(esc.(__param_types)...)}($(callargs...))
        end
    end
end

function _def!(body, kwargs, callargs)
    for i in 1 : length(body.args)
        bodyex = body.args[i]
        if bodyex isa Symbol # var
            push!(kwargs.args, bodyex)
            push!(callargs, bodyex)
        elseif bodyex isa Expr 
            if bodyex.head === :(=)
                rhs = bodyex.args[2]
                lhs = bodyex.args[1] 
                if lhs isa Expr && lhs.head === :(::) # var::T = 1
                    var = lhs.args[1] 
                elseif lhs isa Symbol # var = 1
                    var = lhs
                elseif lhs isa Expr && lhs.head == :call # inner constructors
                    continue
                end
                push!(kwargs.args, Expr(:kw, var, esc(rhs)))
                push!(callargs, var)
                body.args[i] = lhs 
            elseif bodyex.head === :(::)  # var::T
                var = bodyex.args[1]
                push!(kwargs.args, var)
                push!(callargs, var)
            end
        end
    end
end

