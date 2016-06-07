scene = Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=5)
using JLD
save("/storage/malmaud/kinect/pickup1/scene.jld", Dict("scene"=>scene))
