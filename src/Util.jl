module Util

export @not_impl, @ifnull, logsumexp, clip

using MacroTools
using NumericFuns

macro not_impl(expr)
    has_match = @capture expr f_(args__)
    if has_match
        err_msg = "Function $f not implemented"
        esc(quote
            function $f($(args...))
                error($err_msg)
            end
        end)
    else
        error("Incorrect syntax for @not_impl")
    end
end

macro ifnull(e, err)
    esc(quote
        isnull($e) && error($err)
        get($e)
    end)
end

function NumericFuns.logsumexp(x::Vector{Float64})
    reduce(logsumexp, x)
end

function clip(x, lb, ub)
    x<lb && return lb
    x>ub && return ub
    return x
end

end
