# This file includes utilities for Models module.
import Dates.now

"""
    @siminfo msg

Prints an info mesage alongside the current system time.
"""
macro siminfo(msg...)
    quote
        @info "$(now()) $($msg...)"
    end
end
