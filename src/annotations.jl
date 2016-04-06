using Compat

str_to_bool(x) = bool(parse(Int, x))

function parse_line(line)
    parts = split(line, " ")
    track_id = parse(Int, parts[1])
    ul = Point(parse(Int, parts[2]), parse(Int, parts[3]))
    lr = Point(parse(Int, parts[4]), parse(Int, parts[5]))
    detection = Detection(ul, lr, NaN, convert(Symbol, parts[10][2:end-1]))
    frame_id = parse(Int, parts[6])
    Annotation(
        track_id, detection, frame_id, str_to_bool(parts[7]),
        str_to_bool(parts[8]), str_to_bool(parts[9])
    )
end

function parse_file(filename)
    lines = split(readstring(filename), "\n")[1:end-1]
    annotations = [parse_line(line) for line in lines]
end

function to_detector_results(annotations)
    n_frames = maximum([_.frame_id for _ in annotations]) + 1
    n_tracks = maximum([_.track_id for _ in annotations]) + 1
    frames = [FrameDetection(Detection[]) for _ in 1:n_frames]
    tracks = [Track(Int[]) for _ in 1:n_tracks]
    for annotation in annotations
        push!(frames[annotation.frame_id+1].detections, annotation.detection)
        detection_id = length(frames[annotation.frame_id+1].detections)
        push!(tracks[annotation.track_id+1].detection_ids, detection_id)
    end
    DetectionResult(frames), tracks
end

frames,tracks=to_detector_results(anns)
# frames[3].detections
# tracks[2].detection_ids
