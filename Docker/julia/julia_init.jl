for pkg in [:JLD, :PyCall, :MacroTools, :NumericFuns]
    Pkg.add(string(pkg))
    @eval using $pkg
end
