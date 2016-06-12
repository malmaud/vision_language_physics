dirs = ARGS

@sync for dir in dirs
    full_dir = joinpath("/storage/malmaud/kinect", dir, "scene.jld")
    @async begin
        try
            run(`scp devon.csail.mit.edu:$full_dir $full_dir`)
        catch err
            warn("Error downloading $dir")
        end
    end
end
