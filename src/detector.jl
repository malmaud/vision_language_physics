using Images
using PyPlot
using Compat

raw_data(im::Image) = convert(Array{Float64}, data(separate(im)))
raw_data(path::AbstractString) = raw_data(load(path))

function dilate(box_ids, i, j, w, h, box_id, d, threshold, checked)
    if i<1 || j<1 || i>w || j>h
        return
    end
    if checked[i,j]
        return
    end
    checked[i,j]=true
    if d[i,j]>threshold
        return
    end
    if box_ids[i,j]==0
        box_ids[i,j]=box_id
        dilate(box_ids, i-1, j, w, h, box_id, d, threshold, checked)
        dilate(box_ids, i+1, j, w, h, box_id, d, threshold, checked)
        dilate(box_ids, i, j-1, w, h, box_id, d, threshold, checked)
        dilate(box_ids, i, j+1, w, h, box_id, d, threshold, checked)
    end

end

function run_pumpkin_detector(frame)
    detections = Vector{Detection}()
    base_color = [191, 103, 1]/255
    w, h = size(frame,1), size(frame, 2)
    d = Array{Float64}(w, h)
    threshold = .1
    for i=1:w
        for j=1:h
            d[i, j] = (frame[i,j,1]-base_color[1])^2 + (frame[i,j,2]-base_color[2])^2 + (frame[i,j,3]-base_color[3])^2
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
                if box_ids[i,j]==box_id
                    min_x = min(min_x, j)
                    max_x = max(max_x, j)
                    min_y = min(min_y, i)
                    max_y = max(max_y, i)
                end
            end
        end
        push!(detections,
            Detection(Point(min_x, min_y), Point(max_x, max_y),
                0.0, :pumpkin))
    end
    # detections = filter(d->width(d)>1, detections)
    d,box_ids, detections
end

function run_detectors(frame)
    detections = Vector{Detection}()
    append!(detections, run_pumpkin_detector(frame))
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
