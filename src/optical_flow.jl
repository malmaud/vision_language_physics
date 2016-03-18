using Compat
using PyCall

@pyimport cv2

function calc_flow(frame1::Matrix{UInt8}, frame2::Matrix{UInt8})
    flow = cv2.calcOpticalFlowFarneback(frame1, frame2, 0.5, 3, 15, 3, 5, 1.2, 0)
end

function calc_flow(frame1::Matrix{Float64}, frame2::Matrix{Float64})
    calc_flow(round(UInt8, frame1*255), round(UInt8, frame2*255))
end

function calc_flow(frame1::Array{Float64, 3}, frame2::Array{Float64, 3})
    calc_flow(squeeze(mean(frame1, 3), 3), squeeze(mean(frame2, 3), 3))
end
