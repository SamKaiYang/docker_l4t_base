FROM nvcr.io/nvidia/l4t-base:r32.3.1
#指定docker image存放位置
VOLUME ["/storage"]
MAINTAINER sam tt00621212@gmail.com

#root模式
USER root
#環境
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_FRONTEND=noninteractive
#-----------Install CUDA for l4t-base 
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends make g++

COPY ./samples /Documents/docker_sample/l4t-base/samples
COPY ./opencvbuild /Documents/docker_sample/l4t-base/opencvbuild
COPY ./installROSXavier /Documents/docker_sample/l4t-base/installROSXavier
COPY ./darknet /Documents/docker_sample/l4t-base/darknet
COPY ./cmake-3.12.1 /Documents/docker_sample/l4t-base/cmake-3.12.1
#COPY ./samples /tmp/samples

WORKDIR /Documents/docker_sample/l4t-base/samples/1_Utilities/deviceQuery
#WORKDIR /tmp/samples/1_Utilities/deviceQuery
RUN make clean && make

CMD ["./deviceQuery"]

#--------Install ROS melodic
RUN sudo apt-get update && sudo apt-get install --assume-yes apt-utils  && \
    sudo apt-get -y install debconf-utils && \
    #setting system clock
    sudo apt-get update && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y tzdata && \
    ln -fs /usr/share/zoneinfo/Europe/Stockholm /etc/localtime && \
    echo “Asia/Taipei” > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    export DEBIAN_FRONTEND=noninteractive
#RUN sudo apt-get upgrade -y\
RUN apt-get install -y git && \
    apt-get install -y vim && \
    apt-get install -y gedit
#solve Error debconf
RUN apt-get install dialog apt-utils -y
RUN echo '* libraries/restart-without-asking boolean true' | sudo debconf-set-selections
#Fix not find lsb-release
RUN apt-get update && apt-get install -y lsb-release && apt-get clean all

#Fix add-apt-repository: command not found error
RUN sudo apt-get install -y software-properties-common
WORKDIR /Documents/docker_sample/l4t-base/installROSXavier

RUN chmod +x ./installROS.sh
#安裝會有互動訊息 尚未解決
RUN ./installROS.sh -p ros-melodic-desktop -p ros-melodic-rgbd-launch
#RUN source /opt/ros/melodic/setup.sh

#----------------Install opencv 3.4.9
RUN sudo apt-get purge -y libopencv* && \
    sudo apt-get install -y build-essential && \
    sudo apt-get install -y cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev && \
    sudo apt-get install -y python-dev python-numpy python3-dev python3-numpy libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev 

#Install Qt on Ubuntu opencv需要
RUN sudo apt-get install -y qtcreator && \
    sudo apt-get install -y qt5-default && \
    sudo apt-get install -y qt5-doc && \
    sudo apt-get install -y qt5-doc-html qtbase5-doc-html && \
    sudo apt-get install -y qtbase5-examples 

WORKDIR /Documents/docker_sample/l4t-base/opencvbuild/opencv-3.4.9
RUN mkdir -p build
WORKDIR /Documents/docker_sample/l4t-base/opencvbuild/opencv-3.4.9/build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=/usr/local/ -DINSTALL_PYTHON_EXAMPLES=ON -DINSTALL_C_EXAMPLES=ON -DPYTHON_EXCUTABLE=/usr/bin/python -DOPENCV_EXTRA_MODULES_PATH=/Documents/docker_sample/l4t-base/opencvbuild/opencv_contrib-3.4.9/modules -DWITH_CUDA=OFF -DWITH_CUFFT=OFF -DWITH_CUBLAS=OFF -DWITH_TBB=ON -DWITH_V4L=ON -DWITH_QT=ON -DWITH_GTK=ON -DWITH_OPENGL=ON -DENABLE_PRECOMPILED_HEADERS=OFF -DBUILD_EXAMPLES=ON ..
RUN make -j8
RUN sudo make install

#---------Install tensorflow
RUN sudo apt-get update && \
    sudo apt-get install -y libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev && \
    sudo apt-get install -y python3-pip && \
    sudo pip3 install -U pip testresources setuptools && \
    sudo apt-get install -y python3-h5py && \
    sudo pip3 install -U numpy==1.16.1 future==0.17.1 mock==3.0.5 keras_preprocessing==1.0.5 keras_applications==1.0.8 gast==0.2.2 enum34 futures protobuf && \
    sudo pip3 install --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v42 tensorflow-gpu==1.13.1+nv19.3
#slove h5py futurewarning
RUN sudo apt-get purge -y python3-h5py

#-----update cmake 3.12.1
WORKDIR /Documents/docker_sample/l4t-base/cmake-3.12.1
RUN cmake . && \
    make -j8 && \
    sudo make install && \
    sudo update-alternatives --install /usr/bin/cmake cmake /usr/local/bin/cmake 1 --force
#----build yolo v4
WORKDIR /Documents/docker_sample/l4t-base/darknet
RUN cmake .
RUN make

# #使用者新增
RUN useradd -ms/bin/bash iclab

USER iclab
WORKDIR /home/iclab

