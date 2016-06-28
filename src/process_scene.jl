using JLD

include("JMain.jl")

base = joinpath("/storage/malmaud/kinect2", ENV["VIDEOID"])
max_frames = parse(Float64, get(ENV, "MAX_FRAMES", "Inf"))
info("Starting load...")
scene = JMain.Scenes.load_scene(base, max_frames=max_frames)
info("Done")
save(joinpath(base, "scene.jld"), Dict("scene"=>scene))
