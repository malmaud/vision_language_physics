@sync for dir in ARGS
    full_dir = joinpath("/storage/malmaud/kincet", dir)
    @async run(`docker run -e VIDEOID=$dir -v /storage:/storage process_scene`)
end
