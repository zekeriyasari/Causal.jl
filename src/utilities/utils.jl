# This file includes utiliti functions for Systems module

macro siminfo(msg...)
    quote
        @info "$(now()) $($msg...)"
    end
end


"""
    @def begin name 
        code 
    end

Copy paste macro
"""
macro def(name, code)
    quote
        macro $(esc(name))()
            esc($(Meta.quot(code)))
        end
    end
end

hasargs(func, n) = n + 1 in [method.nargs for method in methods(func)]

function unwrap(container, etype; depth=10)
    for i in 1 : depth
        container = vcat(container...)
        eltype(container) == etype && break
    end
    container
end