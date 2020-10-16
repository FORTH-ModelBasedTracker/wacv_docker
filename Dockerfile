# WACV18 Monocular 3D hand pose estimation Docker 

# This docker file builds a working environment for 
# WACV18. 
# NOTE: This is also part of a docker 101 tutorial
#       so the comments are very verbose.

# For this build we will use ubuntu18.04 
# We will start from the nvidia provided image that also 
# comes with cuda and cudnn and drivers preinstalled.
# Note: There are many containers available. 
#       Before starting your own Dockerfile make sure you find the 
#       closest image to your needs to avoid re-creating the wheel.
FROM nvcr.io/nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04

# COPY from host to docker image.
# NOTE: Make sure you first download the models using the 
# getModels.sh script inside the models folder
# COPY models openpose/models/


# Install basic dependencies for our project
# Some packages need user input during configuration. 
# Since docker build is supposed to be unattended we pass the 
# appropriate ENV variables to configure everything 
# without dialogs (in this case tzdata package)
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" TZ="Europe/Athens" apt-get install -y tzdata
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y libboost-all-dev libpython-dev python-pip \
                    git cmake vim libgoogle-glog-dev libprotobuf-dev protobuf-compiler \
                    libhdf5-dev libatlas-base-dev liblmdb-dev libleveldb-dev \
                    libsnappy-dev wget unzip  apt-utils libpython-dev python-numpy \
                    libtbb-dev libglew-dev libopenni-dev libglm-dev freeglut3-dev libeigen3-dev \
                    libgtk2.0-dev pkg-config

# needed by MonoHand3D
RUN pip install scipy

# define a working directory for our application or shell
WORKDIR /wacv18

# NOTE: Each of the following RUN commands is executed on a new shell
# starting at WORKDIR


# NOTE: Openpose needs opencv with CUDA support. Because of that we have to build it from source
# since the prepackaged binaries provided by Ubuntu do not have GPU support.
# Otherwise we could just do: RUN apt-get install -y libopencv-dev

# Build opencv 
RUN mkdir opencv && cd opencv && wget https://github.com/opencv/opencv/archive/3.4.11.zip && unzip 3.4.11.zip && rm 3.4.11.zip  && \
    mkdir build && cd build && \
    cmake -DWITH_CUDA=ON -DBUILD_EXAMPLES=OFF -DOPENCV_GENERATE_PKGCONFIG=ON ../opencv-3.4.11 && \
    make -j`nproc` && make install


# WACV18 is an old project. The current version Openpose is not compatible any more.
# We clone and checkout the last compatible version (see PyOpenpose README).
RUN git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose.git && \
    cd openpose && git checkout e38269862f05beca9497960eef3d35f9eecc0808 && \
    git submodule update --init --recursive

# NOTE: Openpose comes with a CMake build system. 
# Unfortunatelly the commit we are using here has a bug that breaks the caffe build system for 
# GPUs newer than Pascal. So we are using the old Makefiles for this Dockerfile.

# Build caffee 
COPY config/Makefile.config.caffe openpose/3rdparty/caffe/Makefile.config
RUN cd openpose/3rdparty/caffe/ && \
    make all -j`nproc` && make distribute -j`nproc`

# Build Openpose
COPY config/Makefile.config.openpose openpose/Makefile.config
RUN cd openpose && cp ubuntu_deprecated/Makefile.example Makefile && \
    make all -j`nproc` && make distribute -j`nproc` 

# This would be normally done by cmake but since we used the Makefiles for openpose build:
RUN cp -r openpose/3rdparty/caffe/distribute/* openpose/distribute && \
    ln -s /workspace/models openpose/distribute/models

# NOTE: Each command creates a new image LAYER. 
# Group commands together to minimize the number of layers and speed-up build/startup times.


# Setup environment variables needed by PyOpenpose
# Environment variables are set in the image and inherited by the container.
# applications running in the container have access to these environment vars.
ENV OPENPOSE_ROOT=/wacv18/openpose/distribute
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${OPENPOSE_ROOT}/lib"

# Build PyOpenPose
RUN git clone https://github.com/FORTH-ModelBasedTracker/PyOpenPose.git && \
    mkdir PyOpenPose/build && cd PyOpenPose/build && cmake .. && \
    make -j`nproc` && make install


# Build MBV
# Note: For Ubuntu 16.04 install these extra debs: RUN apt-get install -y libxmu-dev libxi-dev
COPY projects/mbv mbv
RUN mkdir mbv/build && cd mbv/build && \
    cmake -DWITH_Physics=OFF -DWITH_Examples=OFF  .. && \
    make -j`nproc` && make install 

# PyCvUtils
COPY projects/PyCvUtils PyCvUtils

ENV MBV_SDK=/usr/local
ENV MBV_APPS=/usr/local
ENV PYTHONPATH="${PYTHONPATH}:/wacv18/PyCvUtils/src:${MBV_SDK}/lib"

# Build Ceres
RUN mkdir ceres && cd ceres && wget http://ceres-solver.org/ceres-solver-1.14.0.tar.gz && \
    tar -zxvf ceres-solver-1.14.0.tar.gz && mkdir build && cd build && \
    cmake ../ceres-solver-1.14.0 && make -j`nproc` && make install

# Build LevmarIK
COPY projects/LevmarIK LevmarIK
RUN mkdir LevmarIK/build && cd LevmarIK/build && \
    cmake .. && make -j`nproc`&& make install


# Define a mount point to access the host filesystem
VOLUME /workspace
# Set the workspace location (where new code will go)
WORKDIR /workspace