immutable Point
    x::Int
    y::Int
end

immutable Box
    top_left::Point
    bottom_right::Point
end

center(b::Box) = Point((b.top_left.x+b.bottom_right.x)//2, (b.bottom_right.y+b.top_left.y)//2)
compute_distance(b1::Box, b2::Box) = compute_distance(center(b1), center(b2))

function compute_distance(p1::Point, p2::Point)
    return sqrt((p1.x-p2.x)^2 + (p1.y-p2.y)^2)
end

using .Words
include("words/CloseMod.jl")
using .CloseMod


include("a.jl")
include("b.jl")

display(ModA.A(1))
display(ModB.B(1))

super(ModA.A) == super(ModB.B)

super(ModA.A)
