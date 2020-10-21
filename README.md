# Dockerfile for WACV18: Monocular 3D hand tracking in the wild

WACV18: Using a single RGB frame for real time 3D hand pose estimation in the wild


## Docker+GPU 101

This is a short step-by-step intro to install _docker-ce_ and _nvidia-docker_ on a workstation (or cloud server). 
The first is the community edition (ce) of docker and the later is the nvidia backed project that brings GPU support to docker containers.

**Note:** Ubuntu OS and a properly installed NVIDIA GPU (drivers etc) is asssumed. 

**Note:** Docker has very good [documentation](https://docs.docker.com/) and community. Check the docs for more details on Dockerfiles, the docker container registry, docker images and docker containers. 

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

   4. Make sure your user is in the docker group. If not add it (and logout/login):

   ```bash
   sudo usermod -aG docker $USER
   ```
**Note:** Taken from the official nvidia-docker instructions [here](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#installing-on-ubuntu-and-debian).

Done! You should be ready to test docker containers with Nvidia GPU support now:

```bash
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

**Note:** The docker CLI tools are very powerfull. All commands are grouped under docker (similar to the git CLI phylosophy). Use ```docker --help``` and ```docker <cmd> --help``` to get started.

## Docker basic concepts

A **Dockerfile** is a recipe for creating docker images. The recipe is executed with ```docker build``` and the result is a **docker image**.
The **image** is used to start **containers** and run your applications in them.

An image is _immutable_ and can be used to start multiple containers. Containers are _mutable_ instances of an image.

A **container registry** is a repository of Dockerfiles and images (not containers). Similar to package repositories of your favorite linux distro. Multiple container registries are available. The official is [dockerhub](https://hub.docker.com/). You typically start your dockerfile by "subclassing" one of these premaid images (see next section for details).

## Preparing to build the WACV18 image

First we need to clone all the relevant projects from our git server (MBV, LevmarIK, Monohand3D), and download the openpose models.
1. Go to the **projects** folder and follow the [instructions](projects/README.md).
2. Go to the **models** folder and download the openpose models using:
   ```bash
   getModels.sh
   ```

## WACV18 Dockerfile

The Dockerfile in this repository creates an image with all the dependencies needed to work on the WACV18 Monocular 3D hand tracking codebase. Check the comments in [Dockerfile](Dockerfile) for a step by step walkthrough of the commands.

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
docker run -it --gpus all --name wacv_cnt --rm -v $PWD:/workspace -e DISPLAY=$DISPLAY --device /dev/video0 -v /tmp/.X11-unix:/tmp/.X11-unix wacv_image
```

**Note:** The **-e** passes an environment variable to the new container. The **--device** will link the corresponding container device to the host. In this example we are using the usb camera.

Now we can run some test scripts in the container. First allow incoming connections to your host X server. Run the following on the host:
```bash
xhost +
```

Lets try the PyOpenPose sample scripts. On the container terminal enter the following
```bash
cd /wacv18/PyOpenPose/scripts
python OpLoop.py
```

You should be able to see live video from your webcam with the OpenPose visualizations.



## VSCode and Docker

VSCode has excellent support for docker. Install the **Docker** plugin by Microsoft and you can browse and manage images and containers from inside vscode.
Moreover when a container is running you can **attach vscode** to it and work as you would normally on your local machine!

### VSCode and Remote Docker 
If you are working remotelly you can attach to remote docker containers as well.
First configure you ssh pub-key with the remote machine to enable password-less logins.

The configure the docker context using vscode
1. Install the following plugins to vscode: docker, Remote-Development
2. Go to your workspace preferences: ctrl+shift+p -> Prefferences -> Open workspace Settings
3. Search for **docker.host**
4. Enter your remote host url. i.e ```ssh://padeler@192.168.10.10:22```

Now go to the docker tab in vscode and you will see the containers and images available on the remote host.
Right click on a container to attach.

**Note:** You can also configure the remote host using "docker context" but when using multiple remote hosts with non static ips (i.e GCP) I found this is the cleaner way.
