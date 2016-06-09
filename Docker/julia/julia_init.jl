for pkg in [:JLD, :PyCall, :MacroTools]
    Pkg.add(string(pkg))
    @eval using $pkg
end
