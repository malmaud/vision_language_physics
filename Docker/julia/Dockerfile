FROM continuumio/anaconda
RUN conda install opencv -y
RUN apt-get update -y
RUN apt-get install -y bar time binutils gcc g++ libssl-dev gfortran curl git xz-utils python m4 make cmake bzip2 hdf5-tools 
RUN git clone https://github.com/JuliaLang/julia.git /julia
WORKDIR /julia
RUN git checkout def71fe
ADD Make.user .
RUN make
ADD julia_init.jl /root
ENV CURL_CA_BUNDLE /etc/ssl/certs/ca-certificates.crt
RUN /julia/julia /root/julia_init.jl
CMD ["/julia/julia"]
