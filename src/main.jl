using Compat
using Images

include("types.jl")
include("optical_flow.jl")

function center(d::Detection)
    Point((d.ul.x+d.lr.x)/2, (d.lr.x+d.lr.y)/2)
end

function distance(c1::Point, c2::Point)
    sqrt((c1.x-c2.x)^2 + (c2.y-c1.y)^2)
end

Images.width(p1::Point, p2::Point) = abs(p2.x - p1.x)
Images.width(d::Detection) = width(d.ul, d.lr)

distance(d1::Detection, d2::Detection) = distance(center(d1), center(d2))

function motion_coherence_score(distance)
    α = 50.0
    β = -1/11
    1 ./ (1+exp(-β*(distance-α)))
end

function normed_detector_score(s)
    α = 1.0
    β = 2.0
    1 ./ (1+exp(-β*(s-α)))
end

function score(t::Track, res::DetectorResult)
    score = 0.0
    for (frame_id, detection_id) in enumerate(t.detection_ids)
        detection = res.frames[frame_id].detections[detection_id]
        score += normed_detector_score(detection.score)
        if frame_id > 1
            last_detection = res.frames[frame_id-1].detections[detection_id]
            score += motion_coherence_score(distance(detection, last_detection))
        end
    end
    score
end



function does_accept(::FarPredicate, d1::Detection, d2::Detection, params)
    c1, c2 = center(d1), center(d2)
    distance = abs(c1.x - c2.x)
    distance - width(d1)/2 - width(d2)/2 > params.far
end

function does_accept(::ClosePredicate, d1, d2, params)
    c1, c2= center(d1), center(d2)
    distance = abs(c1.x - c2.x)
    distance - width(d1)/2 - width(d2)/2 < params.close
end

function does_accept(::LeftOfPredicate, d1, d2, params)
    c1, c2 = center(d1), center(d2)
    return c1.x < c2.x + params.pp
end

function does_accept(::LiftPredicate, d1, params)

end


does_accept(::StationaryPredicate, d1, params) = true

function does_accept(::StationaryButFarPredicate, d1, d2, params)
    does_accept(FarPredicate, d1, d2, params) &&
    does_accept(StationaryPredicate, d1, params) &&
    does_accept(StationaryPredicate, d2, params)
end


function does_accept(::FromLeftWord, t1::Track, t2::Track, detections, params)
    needed_frames = 5
    matched_frames = 0
    for (frame_id, frame) in detections.frames
        d1 = frame.detections[t1.detection_ids[frame_id]]
        d2 = frame.detections[t2.detection_ids[frame_id]]
        if does_accept(LeftOfPredicate, d1, d2, params)
            matched_frames += 1
            if matched_frames ≥ needed_frames
                return true
            end
        else
            matched_frames = 0
        end
    end
    return false
end

function find_track(res::DetectorResult, word::Word)
end



include("detector.jl")



function load_frames(path)
    ids = Int[]
    data = Array{Float64, 3}[]
    for file in readdir(path)
        m = match(r".*?(\d+).*", file)
        if m !== nothing
            push!(ids, parse(Int, m.captures[1]))
            push!(data, raw_data(joinpath(path, file)))
        end
    end
    pixel_data = data[sortperm(ids)]
    flow = Array{Float64,3}[]
    for i=1:length(ids)-1
        push!(flow, calc_flow(pixel_data[i], pixel_data[i+1]))
    end
    ClipSequence(pixel_data, flow)
end
