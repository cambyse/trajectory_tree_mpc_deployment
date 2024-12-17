FROM ubuntu:20.04
# Set environment variables to disable prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install tzdata and configure timezone
RUN apt-get update && apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# Reset DEBIAN_FRONTEND to default
ENV DEBIAN_FRONTEND=dialog

# Install dependencies
RUN apt update && apt install -y git build-essential \
 liblapack-dev \
 mesa-common-dev \
 libeigen3-dev \
 freeglut3-dev \
 libf2c2-dev \
 libjsoncpp-dev \
 libqhull-dev \
 libann-dev \
 libassimp-dev \
 libglew-dev \
 libglfw3-dev \
 libgtest-dev \
 libopencv-dev \
 libboost-all-dev \
 cmake \
 curl \
 git-lfs
 
# Install ROS
RUN echo "deb http://packages.ros.org/ros/ubuntu focal main" | tee /etc/apt/sources.list.d/ros-latest.list
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN apt update

ENV DEBIAN_FRONTEND=noninteractive

RUN apt install -y ros-noetic-desktop gazebo11 ros-noetic-gazebo-ros-pkgs ros-noetic-gazebo-ros-control

ENV DEBIAN_FRONTEND=dialog

RUN mkdir -p /catkin_ws/src
WORKDIR /catkin_ws
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make"
WORKDIR /catkin_ws/src

# Clone OSQP
RUN mkdir -p /osqp
WORKDIR /osqp
RUN git clone https://github.com/osqp/osqp
WORKDIR /osqp/osqp
RUN git checkout v0.6.2
RUN git submodule update --init --recursive
RUN mkdir -p build
WORKDIR /osqp/osqp/build
RUN cmake -G "Unix Makefiles" ..
RUN cmake --build .
RUN cmake --build . --target install

# Clone projects
WORKDIR /catkin_ws/src
RUN git clone https://github.com/cambyse/trajectory_tree_mpc.git
WORKDIR /catkin_ws/src/trajectory_tree_mpc
RUN git submodule update --init --recursive

# Build Rai
WORKDIR /catkin_ws/src/trajectory_tree_mpc/control_tree_car/externals/rai
RUN make

# Build ros nodes
WORKDIR /catkin_ws
RUN /bin/bash -c "source /opt/ros/noetic/setup.bash && catkin_make"

# Install gazebo models

