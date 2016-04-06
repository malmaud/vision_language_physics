using Images
using PyPlot
using Compat
using FastAnonymous

raw_data(im::Image) = convert(Array{Float64}, data(separate(im)))
raw_data(path::AbstractString) = raw_data(load(path))

macro neighbors(coords...)
    e = Expr(:tuple)
    for (idx, coord) in enumerate(coords)
        for sign in [:+, :-]
            e2 = Expr(:tuple)
            for (idx2, coord2) in enumerate(coords)
                if idx==idx2
                    push!(e2.args, :($sign($coord, 1)))
                else
                    push!(e2.args, coord2)
                end
            end
            push!(e.args, e2)
        end
    end
    e
end

function isoutbounds(x, y, w, h)
    x<1 || y<1 || x>w || y>h
end

function dilate(box_ids, i, j, w, h, box_id, d, threshold, checked)
    isoutbounds(i, j, w, h) && return
    checked[i, j] && return
    checked[i,j] = true
    if d[i,j] > threshold
        return
    end
    if box_ids[i,j] == 0
        box_ids[i,j] = box_id
        for (x_coord, y_coord) in @neighbors(i,j)
            dilate(box_ids, x_coord, y_coord, w, h, box_id, d, threshold, checked)
        end
    end

end

function run_color_detector(frame, threshold, base_color, object_name)
    detections = Vector{Detection}()
    w, h = size(frame,1), size(frame, 2)
    d = Array{Float64}(w, h)
    for i=1:w
        for j=1:h
            ssq=0.0
            for c=1:3
                ssq += (frame[i, j, c] - base_color[c])^2
            end
            d[i, j] = ssq
        end
    end
    box_ids = zeros(Int, w, h)
    cur_box_id = 0
    checked = Array(Bool, w,h)
    checked[:] = false
    for i=1:w
        for j=1:h
            if box_ids[i,j]==0 && d[i,j]<threshold
                cur_box_id +=1
                dilate(box_ids, i, j, w, h, cur_box_id, d, threshold, checked)

                checked[:] = false
            end
        end
    end
    n_boxes = cur_box_id
    for box_id in 1:n_boxes
        min_x, min_y = w+1, h+1
        max_x, max_y = 0, 0
        for i=1:w
            for j=1:h
                if box_ids[i,j] == box_id
                    min_x = min(min_x, j)
                    max_x = max(max_x, j)
                    min_y = min(min_y, i)
                    max_y = max(max_y, i)
                end
            end
        end
        push!(detections,
            Detection(Point(min_x, min_y), Point(max_x, max_y),
                0.0, object_name))  # todo calculate actual score
    end
    filter(d->width(d)>2, detections)
end

run_pumpkin_detector(frame) = run_color_detector(
    frame, .1, [191, 103, 1]/255, :pumpkin)

run_ball_detector(frame) = run_color_detector(
    frame, .1, [19, 128, 221]/255, :ball)

function run_detectors(frame)
    detections = Vector{Detection}()
    for detector in [run_pumpkin_detector, run_ball_detector]
        append!(detections, detector(frame))
    end
    return FrameDetection(detections)
end

function PyPlot.plot(d::Detection)
    ax = gca()
    width = d.lr.x - d.ul.x
    height = d.lr.y - d.ul.y
    rect = matplotlib[:patches][:Rectangle]([d.ul.x, d.ul.y], width, height, fill=false)
    ax[:add_patch](rect)
end

PyPlot.plot(d::Vector{Detection}) = map(plot, d)

function run_test()
    d, box_ids, detections = run_pumpkin_detector(frame)
    figure()
    imshow(frame)
    plot(detections)
    draw()
end
