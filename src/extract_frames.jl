basedir = "/storage/malmaud/kinect"
for dir in readdir(basedir)
    isdir(joinpath(basedir, dir)) || continue
    base = joinpath(basedir, dir, "color")
    isdir(joinpath(base, "frames")) || mkdir(joinpath(base, "frames"))
    cmd = run(`ffmpeg -i $(joinpath(base, "movie.avi")) -r 30/1 $(joinpath(base, "frames/output%03d.jpg"))`)
end
