basedir = "/storage/malmaud/kinect"
@sync for dir in readdir(basedir)
    isdir(joinpath(basedir, dir)) || continue
    for channel in ["color", "depth"]
        base = joinpath(basedir, dir, "depth")
        isdir(joinpath(base, "frames")) || mkdir(joinpath(base, "frames"))
        @async run(`ffmpeg -i $(joinpath(base, "movie.avi")) -r 30/1 $(joinpath(base, "frames/output%03d.jpg"))`) # TODO change to %04d
    end
end
