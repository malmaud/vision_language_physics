"""
Methods for loading and representing 3D physical scenes/vignettes in terms of tracks of bounding boxes of objects of interest.
"""
module Scenes

export Frame, Box, compute_distance, TRACK_MAP, Scene

try
    using PyPlot
    import PyPlot: plot
end
using ..Util

using PyCall
@pyimport matplotlib.patches as patches
@pyimport cv2
import Base: +, -

const TRACK_MAP = Dict("right_hand"=>1, "left_hand"=>2, "rat"=>3, "monkey"=>4, "car"=>5, "person"=>6, "aeroplane"=>7, "bird"=>8, "bottle"=>9, "pottedplant"=>10, "tvmonitor"=>11)
const MAX_BOXES = 10

immutable Point{T}
    x::T
    y::T
    z::T
end

function Base.show(io::IO, p::Point)
    print(io, @sprintf("Point(%.1f, %.1f, %.1f)", p.x, p.y, p.z))
end

Point(x, y, z) = Point(promote(x, y, z)...)
Point(x, y) = Point(x, y, 0.0)

for op in [:-, :+]
    @eval $op(p1::Point, p2::Point) = Point($op(p1.x, p2.x), $op(p1.y, p2.y), $op(p1.z, p2.z))
end

immutable Box
    top_left::Point{Float64}
    bottom_right::Point{Float64}
end

function Base.show(io::IO, box::Box)
    print(io, @sprintf("(%.2f, %.2f, %.2f, %.2f, %.2f, %.2f)", box.top_left.x, box.top_left.y, box.top_left.z, box.bottom_right.x, box.bottom_right.y, box.bottom_right.z))
end

function plot(box::Box, box_id=1)
    color_wheel = ["red", "green", "blue", "orange", "purple", "red", "green", "blue", "orange", "purple"]
    ax = gca()
    # TODO: switch to coloring based on track id instead of box id
    z = max(50, box.top_left.z)
    ax[:add_patch](
    patches.Rectangle((box.top_left.x, box.top_left.y), box.bottom_right.x-box.top_left.x, box.bottom_right.y-box.top_left.y,
     fill=false,
     linewidth=round(Int, z/255*10),
     edgecolor=color_wheel[mod1(box_id, length(color_wheel))]))
end

center(b::Box) = Point((b.top_left.x+b.bottom_right.x)/2, (b.bottom_right.y+b.top_left.y)/2, (b.bottom_right.z+b.top_left.z)/2)
compute_distance(b1::Box, b2::Box) = compute_distance(center(b1), center(b2))

function compute_distance(p1::Point, p2::Point)
    return sqrt((p1.x-p2.x)^2 + (p1.y-p2.y)^2 + (p1.z-p2.z)^2)
end

type Frame
    boxes::Vector{Box}
    optical_flows::Array{Float64, 2}
    object_scores::Array{Float64, 2}
end

OBJECTS = keys(TRACK_MAP)|>collect

Frame(boxes::Vector{Box}) = Frame(boxes,  zeros(Float64, length(boxes), 2), zeros(Float64, MAX_BOXES, length(OBJECTS)))
Frame() = Frame(Box[])

type Scene
    color::Nullable{Array{UInt8, 4}}
    depth::Nullable{Array{Float64, 3}}
    flow::Nullable{Array{Float64, 4}}
    detections::Nullable{Vector{Frame}}
    path::Nullable{String}
end

function Base.show(io::IO, scene::Scene)
    if !isnull(scene.path)
        print(io, "Scene($(get(scene.path)))")
    else
        print(io, "Scene")
    end
end

Scene() = Scene(Nullable{Array{UInt8,4}}(), Nullable{Array{Float64, 3}}(), Nullable{Array{Float64, 4}}(), Nullable{Vector{Frame}}(), Nullable{String}())

function load_color_frame(path)
    raw =  cv2.imread(path)
    return cv2.cvtColor(raw, cv2.COLOR_BGR2RGB)
end

function load_depth_frame(path)
    raw = cv2.imread(path)
    return raw
end

function plot(scene::Scene, frame_id::Int; show_boxes=true, show_flow=true)
    path = @ifnull scene.path "Scene doesn't have path information"
    filename = @sprintf("output%03d.jpg", frame_id)
    frame = load_color_frame(joinpath(path, "color", "frames", filename))
    imshow(frame)
    if !isnull(scene.detections)
        detections = get(scene.detections)
        X = Int[]
        Y = Int[]
        for (box_id, box) in enumerate(detections[frame_id].boxes)
            if show_boxes
                plot(box, box_id)
            end
            push!(X, round(Int, center(box).x))
            push!(Y, round(Int, center(box).y))
        end
        flows = detections[frame_id].optical_flows
        flows ./= sqrt(sum(flows.^2, 2))*10
        if show_flow
            quiver(X, Y, flows[:, 1], flows[:, 2])
        end
    end
end

const turk_width = 720
const turk_height = 405
const depth_width = 512
const depth_height = 424
const real_width = 1920
const real_height = 1080

function load_annotations(frames, path)
    const track_id=1
    const xmin=2
    const ymin=3
    const xmax=4
    const ymax=5
    const frame=6
    const lost=7
    const occluded=8
    const generated=9
    const label=10

    width_ratio = real_width/turk_width
    height_ratio = real_height/turk_height
    data = readdlm(path)
    already_seen = Set{Tuple{Int, Int}}()  # If multiple annotators labeled the same object and the same frame, only use the first
    depth_path = joinpath(dirname(path), "depth", "frames")
    for row in 1:size(data, 1)
        track_id = TRACK_MAP[data[row, label]]
        frame_id = data[row, frame]+1
        get_point = (ratio, x, y) -> get_depth(ratio*x, ratio*y, depth_path, frame_id)
        ul = get_point(width_ratio, data[row, xmin], data[row, ymin])
        lr = get_point(height_ratio, data[row, xmax], data[row, ymax])
        box = Box(ul, lr)

        (frame_id, track_id) ∈ already_seen && continue
        push!(already_seen, (frame_id, track_id))
        push!(frames[frame_id].boxes, box)
        frames[frame_id].object_scores[length(frames[frame_id].boxes), track_id] = 1.0
    end
end

function load_rcnn_detections(frames, path)
    data, header = readdlm(path, ',', header=true)
    const frame=1
    const detection=2
    const label=3
    const score = 4
    const b0=5
    const b1=6
    const b2=7
    const b3=8
    const SCORE_THRES = .5
    for row in 1:size(data, 1)
        frame_idx = data[row, frame]
        depth_for =  (b0, b1) -> get_depth(data[row,b0], data[row,b1], joinpath(dirname(path),"..","..","depth","frames"), frame_idx)
        data[row, score] < SCORE_THRES && continue
        box = Box(depth_for(b0,b1), depth_for(b2,b3))
        push!(frames[frame_idx].boxes, box)
        class_idx= TRACK_MAP[data[row, label]]
        frames[frame_idx].object_scores[length(frames[frame_idx].boxes), class_idx] = data[row, score]
    end
end

function get_depth(x, y, depth_path, frame_idx)
    frame_path = (joinpath(depth_path, @sprintf("output%03d.jpg", frame_idx)))
    frame = load_depth_frame(frame_path)
    depth_x = clamp(round(Int, x/real_width*depth_width), 1, depth_width)
    depth_y = clamp(round(Int, y/real_height*depth_height), 1, depth_height)

    z = frame[depth_y, depth_x, 1] |> Int # opencv inverts the width, height dimensions
    return Point(clamp(x, 1, real_width) , clamp(y, 1, real_height), clamp(z, 0, 256))
    # return Point(x, y, z)
end

function load_hand_positions(frames::Vector{Frame}, path)
    const frame_id = 1
    const person_id = 2
    const right_hand_x = 3
    const right_hand_y = 4
    const left_hand_x = 5
    const left_hand_y = 6
    const width = 50

    points = readcsv(path)
    correspondance_file = joinpath(dirname(path), "color", "frame_correspondance.csv") |> readcsv
    depth_path = joinpath(dirname(path), "depth", "frames")
    correspondance = Dict{Int, Int}()
    for row in 2:size(correspondance_file, 1)
        correspondance[correspondance_file[row, 2]] = correspondance_file[row, 1] + 1
    end
    for row in 2:size(points, 1)
        points[row, person_id] == 0 && continue
        true_frame = points[row, frame_id]
        (true_frame ∉ keys(correspondance)) && continue
        frame = correspondance[true_frame]
        frame > length(frames) && continue
        for (hand, pos_x, pos_y) in [("right_hand", points[row, right_hand_x], points[row, right_hand_y]), ("left_hand", points[row, left_hand_x], points[row, left_hand_y])]
            if isa(pos_x, Number)
                top_left = get_depth(pos_x - width/2, pos_y-width/2, depth_path, frame)
                bottom_right = get_depth(pos_x + width/2, pos_y+width/2, depth_path, frame)
                push!(frames[frame].boxes, Box(top_left, bottom_right))
                frames[frame].object_scores[length(frames[frame].boxes), TRACK_MAP[hand]] = 1.0
            end
        end
    end
end

function load_scene(path; max_frames=1)
    ids = Dict{Int, String}()
    for file in readdir(joinpath(path, "color/frames"))
        m = match(r".*?(\d+)\.jpg", file)
        if m !== nothing
            id = m.captures[1]
            ids[parse(Int, id)] = file
        end
    end
    scene = Scene()
    scene.path = path
    detections = Frame[]
    n_frames = maximum(keys(ids))
    for frame in 1:n_frames
        push!(detections, Frame())
    end

    if isfile(joinpath(path, "hand_points.csv"))
        load_hand_positions(detections, joinpath(path, "hand_points.csv"))
    end
    if isfile(joinpath(path, "color", "frames", "rcnn.csv"))
        load_rcnn_detections(detections, joinpath(path, "color", "frames", "rcnn.csv"))
    end
    if isfile(joinpath(path, "annotations.txt"))
        load_annotations(detections, joinpath(path, "annotations.txt"))
    end
    scene.detections = Nullable(detections)
    calc_optical_flow(scene, max_frames)  # TODO: temporary for debugging purposes
    return scene
end

function calc_optical_flow(frame1::Array{UInt8, 3}, frame2::Array{UInt8, 3})
    frame1_im = round(UInt8, mean(frame1, 3))
    frame2_im = round(UInt8, mean(frame2, 3))
    flow = cv2.calcOpticalFlowFarneback(frame1_im, frame2_im, .5, 3, 15, 3, 5, 1.2, 0)
    flow
end

function calc_optical_flow(scene::Scene, max_frames=Inf)
    frames = @ifnull scene.detections "Must get detections first"
    path = @ifnull scene.path "Need a path to compute flow"
    for frame_idx in 1:length(frames)-1
        frame_idx > max_frames && continue
        info("Processing $frame_idx of $(min(max_frames, length(frames)-1))")
        frame = frames[frame_idx]
        img_name = frame_idx->@sprintf("output%03d.jpg", frame_idx)
        full_img_name = frame_idx->joinpath(path, "color", "frames", img_name(frame_idx))
        load_img = frame_idx->load_color_frame(full_img_name(frame_idx))
        im1 = load_img(frame_idx)
        im2 = load_img(frame_idx+1)
        flow = calc_optical_flow(im1, im2)
        all_flow = Array{Float64}(length(frame.boxes), 2)
        frame.optical_flows = all_flow
        for (box_id, box) in enumerate(frame.boxes)
            p = center(box)
            f = flow[clamp(round(Int, p.y), 1, 1920), clamp(round(Int, p.x), 1, 1080), :]  # TODO doublecheck these clamp numbers aren't backwards
            all_flow[box_id, :] = f
        end
    end
end

function show_optical_flow(f1, f2)
    flow = calc_optical_flow(f1, f2)
    _, axes = subplots(1,2)
    sca(axes[1])
    imshow(flow[:,:,1])
    title("X flow")
    sca(axes[2])
    imshow(flow[:,:,2])
    title("Y flow")
end


end
