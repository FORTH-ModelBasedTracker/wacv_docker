# Dockerfile for the WACV18 paper

WACV18: Using a single RGB frame for real time 3D hand pose estimation in the wild


## Docker+GPU 101

This is a short step-by-step intro to install docker-ce and nvidia-docker on a workstation (or cloud server). Ubuntu OS and properly installed NVIDIA GPU (drivers etc) is asssumed.

Note: Docker has very good [documentation](https://docs.docker.com/) and community. Check the docs for more details on Dockerfiles, the docker container registry, docker images and docker containers. 

### Installation

1. Install docker-ce:
   Follow the official instructions [here](https://docs.docker.com/engine/install/ubuntu/).

2. Install nvidia-docker:

   1. Add the nvidia package repository:

   ```bash
   distribution=$(. /etc/os-release;echo $ID$VERSION_ID)

   curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -

   curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

   ```

   2. Install nvidia-docker:
   ```bash
   sudo apt-get update
   sudo apt-get install -y nvidia-docker2
   ```

   3. Restart docker service
   ```bash
   sudo systemctl restart docker
   ```

   4. Make sure your user is in the docker group. If not add it

   ```bash
   sudo usermod -aG docker $USER
   ```
**Note:** Official nvidia-docker instructions [here](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installing-on-ubuntu-and-debian).

Done! You should be ready to test docker containers with Nvidia GPU support now:

```bash
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

**Note:** The docker CLI tools are very powerfull. All commands are grouped under docker (similar to the git CLI phylosophy). Use ```docker --help``` and ```docker <cmd> --help``` to get started.

## Docker basic concepts

A **Dockerfile** is recipy for creating docker images. It is a text file with a series of commands. The commands are executed with ```docker build``` and the result is a **docker image**.
The **image** is used to start **containers** and run your applications in them.

An image is _immutable_ and can be used to start multiple containers. Containers are _mutable_ instances of an image.

A **container registry** is a repository of Dockerfiles and images (not containers). Similar to package repositories of your favorite linux distro. Multiple container registries are available. The official is [dockerhub](https://hub.docker.com/). You typically start your dockerfile by "subclassing" one of these premaid images (see next section for details).

## Preparing to build the WACV18 image

First we need to clone all the relevant projects from our git server: MBV, LevmarIK, Monohand3D.
- Go to the **projects** folder and follow the [instructions](projects/README.md).
- Got to the **models** folder and download the openpose models using
```bash
getModels.sh
```

## WACV18 Dockerfile

The Dockerfile in this repository creates an image with all the dependencies needed to work on the WACV18 Monocular 3D hand tracking codebase. Check the comments in Dockerfile for a step by step walkthrough of the commands.

Once you are done reading it, you can build it like so:

```bash
docker build --tag wacv_image .
```

It will take some time....

Once done you can start a container from the new image like so:

```bash
docker run -it --gpus all --name wacv_cnt --rm  -v $PWD:/workspace wacv_image
```
**Note:** The **-v** flag mounts the provided host folder (in the above the current working directory) to the containers target folder. Similarly you can map ports (TCP or UDP) using the **-p** flag.

**Note:** The **--rm** instructs docker to delete the container on exit. If you want to have keep your changes in the container just remove the flag.

You can start GUI on your host's X server like so:
```bash
docker run -it --gpus all --name wacv_cnt --rm -v $PWD:/workspace -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix wacv_image
```

**Note:** The **-e** passes an environment variable to the new container. 