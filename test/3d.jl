p=Scenes.Point(1,2,3)
p2=Scenes.Point(4,5,6)
Scenes.compute_distance(p, p2)

frame=Scenes.load_depth_frame("/storage/malmaud/kinect/pickup1/depth/frames/output001.jpg");1

using PyPlot
gray=mean(frame,3)[:,:,1]; 1
using PyCall
@pyimport seaborn
figure();seaborn.distplot(frame[:])

size(gray)

Scenes.get_depth(500, 600, "/storage/malmaud/kinect/pickup1/depth/frames", 500)
