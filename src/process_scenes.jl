@sync for dir in ARGS
    full_dir = joinpath("/storage/malmaud/kinect2", dir)
    @async run(`docker run -e VIDEOID=$dir -v /storage:/storage process_scene`)
end
