using JLD
scene=Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=1)

hmm=Trackers.Tracker(scene)
HMMSolver.get_initial_distribution(hmm)
HMMSolver.get_props(hmm)
HMMSolver.get_transition_matrix(hmm,5)
HMMSolver.get_likelihood(hmm, 1, 2, nothing)

frames=get(scene.detections)

path=HMMSolver.get_ml_path(hmm, zeros(length(frames)), 2)

findfirst(path.==1)

using PyPlot

plot(scene, 175)

t=linspace(.1,100,1000)

y=Trackers.sigmoid(t, 50, -1/11)
using PyCall
@pyimport seaborn
figure()
clf();plot(t,y)
title("Motion coherence", fontsize=20)
xlabel("Distance")
ylabel("Coherence")
savefig("/Users/malmaud/Desktop/motion_coherence.pdf")
