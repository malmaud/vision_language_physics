"""
Methods for loading and representing 3D physical scenes/vignettes in terms of tracks of bounding boxes of objects of interest.
"""
module Scenes

export Frame, Box, compute_distance

using Images

immutable Point{T}
    x::T
    y::T
end

immutable Box
    top_left::Point{Int}
    bottom_right::Point{Int}
end

center(b::Box) = Point((b.top_left.x+b.bottom_right.x)//2, (b.bottom_right.y+b.top_left.y)//2)
compute_distance(b1::Box, b2::Box) = compute_distance(center(b1), center(b2))

function compute_distance(p1::Point, p2::Point)
    return sqrt((p1.x-p2.x)^2 + (p1.y-p2.y)^2)
end

immutable Frame
    boxes::Vector{Box}
    track_ids::Vector{Int}
    optical_flows::Array{Float64, 2}
end

Frame(boxes::Vector{Box}) = Frame(boxes, zeros(Int, length(boxes)), zeros(Float64, length(boxes), 2))

type Scene
    color::Nullable{Array{Float64, 4}}
    depth::Nullable{Array{Float64, 3}}
    detections::Nullable{Vector{Frame}}
    path::Nullable{String}
end

Scene() = Scene(Nullable{Array{Float64,4}}(), Nullable{Array{Float64, 3}}(), Nullable{Vector{Frame}}(), Nullable{String}())

function load_color_frame(path)
    im = load(path)
    raw = convert(Array{Float64}, data(separate(im)))
    raw
end

function load_scene(path)
    ids = Dict{Int, String}()
    for file in readdir(joinpath(path, "color"))
        m = match(r".*?(\d+)\.jpg", file)
        if m !== nothing
            id = m.captures[1]
            ids[parse(Int, id)] = file
        end
    end
    scene = Scene()
    scene.path = path
    return scene
end
#load_scene("/storage/malmaud/kinect/pickup1")

end
