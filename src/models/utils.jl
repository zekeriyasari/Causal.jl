# This file includes utilities for Models module.
import Dates.now


macro siminfo(msg...)
    quote
        @info "$(now()) $($msg...)"
    end
end
