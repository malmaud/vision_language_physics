FROM julia
WORKDIR /

RUN git clone https://github.com/malmaud/vision_language_physics.git
WORKDIR /vision_language_physics/src
RUN git checkout run_object_detector
ENV VIDEOID pickup1
CMD ["/julia/julia", "process_scene.jl"]
