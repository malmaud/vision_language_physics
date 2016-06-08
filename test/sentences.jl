#scene=Scenes.load_scene("/storage/malmaud/kinect/pickup1", max_frames=1)
using JLD
#save("/storage/malmaud/kinect/pickup1/pickup1.jld", Dict("scene"=>scene))

scene=load("/storage/malmaud/kinect/pickup1/pickup1.jld")["scene"]

scene.detections = Nullable(get(scene.detections)[1:300])

# A right hand is close to a rat

sentence = Sentences.Sentence()

sentence.n_agents=2

hand=ObjectWords.ObjectWord()
hand.obj_name=:left_hand
hand.tracks = (1,)
push!(sentence.words, hand)

close=CloseWords.CloseWord()
close.tracks = (1,2)
push!(sentence.words, close)

rat = ObjectWords.ObjectWord()
rat.obj_name=:rat
rat.tracks=(2,)
push!(sentence.words, rat)

path=get_score(scene, sentence)

path.path

p=parse(Sentences.Sentence, "Hi from Jon", port=5007)

p
