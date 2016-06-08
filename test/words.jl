scene=Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=1)
scene.detections = Nullable(get(scene.detections)[1:300])
rat=ObjectWords.ObjectWord(scene)

rat.obj_name=:rat
hand=ObjectWords.ObjectWord(scene)

hand.obj_name=:left_hand

close=CloseWords.CloseWord(scene)

tracker1=Trackers.Tracker(scene)
tracker2=Trackers.Tracker(scene)
close.tracks=(1,2)
lattice=HMMSolver.HMMLattice([tracker1,tracker2,close])

frames=get(scene.detections)

path=HMMSolver.get_ml_path(lattice, zeros(length(frames)), (3,))
path.score
