scene=Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=1)

rat=ObjectWords.ObjectWord(:rat, scene)

HMMSolver.get_likelihood(rat, 1, 1, 1, [3])
hand=ObjectWords.ObjectWord(:left_hand, scene)
tracker=Trackers.Tracker(scene)

lattice=HMMSolver.HMMLattice([tracker, hand])
frames=get(scene.detections)
scene.detections=Nullable(frames[1:300])
frames=get(scene.detections)
length(frames)
path=HMMSolver.get_ml_path(lattice, zeros(length(frames)))
path[:]=1
using Atom

#HMMSolver.get_props(rat)
HMMSolver.get_transition_matrix(tracker, 322)

using PyPlot
plot(scene, 323)
