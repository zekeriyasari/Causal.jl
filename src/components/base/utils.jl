# This file includes the utility functions

# """
#     @def(name, code)

# Evaluates the `code` with the `name`. This is basically used to define copy-paste code. 

# # Example
# ```jldoctest
# julia> @def fields begin
#     x::Int
#     y::Float64
#     end
# @fields (macro with 1 method)

# julia> struct Dummy
#     @fields
#     z::Symbol
#     end

# julia> fieldnames(Dummy)
# (:x, :y, :z)

# julia> 
# ```
# """
macro def(name, code)
    quote
        macro $(esc(name))()
            esc($(Meta.quot(code)))
        end
    end
end

# """
#     @def_with_inputs name args code

# Defines the macro `name` with arguments `args` and with the code `code`. See the examples.

# Example
# ```jldoctest
# julia> @def_with_args myname (x, y) begin
#            println("x ", x, " y ", y)
#        end
# @myname (macro with 1 method)

# julia> x, y = 4,5
# (4, 5)

# julia> @myname x y
# x 4 y 5

# julia> 
# end
# ```
# """
macro def_with_args(name, args, code)
    quote
        macro $(esc(name))($(args)...)
            esc($(Meta.quot(code)))
        end
    end
end

