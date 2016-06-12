using .DirectionPreds

pred=DirectionPredicate([-1.0, 0.0])

pred

using JLD

scene = load("/storage/malmaud/kinect/pickup2/scene.jld")["scene"]
scene=Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=3)
frames=get(scene.detections)

using PyPlot

clf(); plot(scene,1)
