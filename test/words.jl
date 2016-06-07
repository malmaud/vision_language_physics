scene=Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=1)
scene.detections = Nullable(get(scene.detections)[1:300])
rat=ObjectWords.ObjectWord(:rat, scene)

hand=ObjectWords.ObjectWord(:left_hand, scene)



close=CloseWords.CloseWord(scene)

tracker1=Trackers.Tracker(scene)
tracker2=Trackers.Tracker(scene)

lattice=HMMSolver.HMMLattice([tracker1,tracker2,close])

frames=get(scene.detections)
path=HMMSolver.get_ml_path(lattice, zeros(length(frames)), 3)
path

Scenes.compute_distance(Scenes.Point(1,1), Scenes.Point(100,100))
