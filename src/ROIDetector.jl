module ROIDetector

using ..Scenes
using JLD
using PyCall
@pyimport tensorflow as tf

immutable Example
    image::String
    box_id::Int
    bounds::Vector{Float64}
end

function extract(::Type{Vector{Example}}, scene::Scene)
    frames = get(scene.detections)
    examples = Example[]
    path = get(scene.path)
    for (frame_idx, frame) in enumerate(frames)
        file_name = @sprintf("output%03d.jpg", frame_idx)
        image_path = joinpath(path, "color", "frames", file_name)
        for box_id in 3:length(frame.boxes)
            box = frame.boxes[box_id]
            bounds = Float64[box.top_left.x, box.top_left.y, box.bottom_right.x, box.bottom_right.y]
            push!(examples, Example(image_path, box_id, bounds))
        end
    end
    return examples
end

extract(::Type{Vector{Example}}, scenes::Vector{Scene}) = mapreduce(scene->extract(Vector{Example}, scene), vcat, scenes)

function extract(::Type{Vector{Example}}, path::String)
    scenes = Scene[]
    for dir in readdir(path)
        p = joinpath(path, dir, "scene.jld")
        if isfile(p)
            push!(scenes, load(p)["scene"])
        end
    end
    extract(Vector{Example}, scenes)
end


function JLD.save(examples::Vector{Example}, filename)
    open(filename, "w") do file
        for example in examples
            println(file, @sprintf("%s %d %f %f %f %f", example.image, example.box_id, example.bounds...))
        end
    end
end

function build_network()

end

end
