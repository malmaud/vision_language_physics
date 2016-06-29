using JLD

scene=load("/storage/malmaud/kinect/pickup1/scene.jld")["scene"]

frames=get(scene.detections)

using PyPlot
clf();plot(scene,100)

frames[35].boxes

clf();plot(scene,35)
