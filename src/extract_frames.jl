basedir = "/storage/malmaud/kinect2"
@sync for dir in readdir(basedir)
    isdir(joinpath(basedir, dir)) || continue
    for channel in ["color", "depth"]
        base = joinpath(basedir, dir, channel)
        isdir(joinpath(base, "frames")) || mkdir(joinpath(base, "frames"))
        @async run(`ffmpeg -i $(joinpath(base, "movie.avi")) -r 30/1 $(joinpath(base, "frames/output%03d.jpg"))`) # TODO change to %04d
    end
end
