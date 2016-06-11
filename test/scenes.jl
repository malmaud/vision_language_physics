scene = Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=5)
using JLD
save("/storage/malmaud/kinect/pickup1/scene.jld", Dict("scene"=>scene))

scene=load("/storage/malmaud/kinect/pickup1/scene.jld")["scene"]

frames=get(scene.detections)

using PyPlot
clf();plot(scene,630)
