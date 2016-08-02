using JLD
empty!(JLD._typedict)
scene = load("/storage/malmaud/kinect/pickup1/scene.jld")["scene"]
#figure();plot(scene,100)
sentence = parse(Sentences.Sentence, "A man picks up a rat.")
res = get_score(scene, sentence)
res.score
using PyPlot
clf(); plot(scene, res, sentence)
