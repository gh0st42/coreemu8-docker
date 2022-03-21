ARG ARCH=
FROM ${ARCH}ubuntu:20.04
LABEL Description="Docker image for core network emulator"


ENV DEBIAN_FRONTEND noninteractive
ENV GRPC_PYTHON_BUILD_EXT_COMPILER_JOBS 8

ARG PREFIX=/usr/local

# development tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    iputils-ping \
    net-tools \
    iproute2 \
    vlan \
    wget \
    curl \
    vim \
    nano \
    mtr \
    tmux \
    iperf \
    git \
    binutils \
    ssh \
    tcpdump \
    && rm -rf /var/lib/apt/lists/*

# CORE dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    quagga \
    psmisc \
    sudo \
    imagemagick \
    docker.io \
    openvswitch-switch \
    automake \
    autoconf \
    bash \
    ca-certificates \
    ethtool \
    gawk \
    gcc \
    g++ \
    iproute2 \
    iputils-ping \
    libc-dev \
    libev-dev \
    libreadline-dev \
    libtool \
    libtk-img \
    libproj-dev \
    proj-bin \
    make \
    nftables \
    python3 \
    python3-dev \
    python3-pip \
    python3-tk \
    pkg-config \
    systemctl \
    tk \
    wget \
    xauth \
    xterm \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install \
    grpcio==1.27.2 \
    grpcio-tools==1.27.2 \
    poetry==1.1.7

# CORE
RUN wget --quiet https://github.com/coreemu/core/archive/release-8.1.0.tar.gz \
    && tar xvf release* \
    && rm release*.tar.gz
#RUN git clone https://github.com/coreemu/core \
#    && cd core \

RUN apt-get update && \
    cd core* &&\
    ./bootstrap.sh && \
    ./configure && \
    make -j $(nproc) && \
    make install && \
    cd daemon && \
    python3 -m poetry build -f wheel && \
    python3 -m pip install dist/* && \
    cp scripts/* ${PREFIX}/bin && \
    mkdir /etc/core && \
    cp -n data/core.conf /etc/core && \
    cp -n data/logging.conf /etc/core && \
    mkdir -p ${PREFIX}/share/core && \
    cp -r examples ${PREFIX}/share/core && \
    echo '\
    [Unit]\n\
    Description=Common Open Research Emulator Service\n\
    After=network.target\n\
    \n\
    [Service]\n\
    Type=simple\n\
    ExecStart=/usr/local/bin/core-daemon\n\
    TasksMax=infinity\n\
    \n\
    [Install]\n\
    WantedBy=multi-user.target\
    ' > /lib/systemd/system/core-daemon.service && \
    #&& ./install.sh \
    #&& export PATH=$PATH:/root/.local/bin \
    #&& inv install-emane \
    rm -rf /var/lib/apt/lists/*

# various last minute deps

WORKDIR /root
RUN git clone https://github.com/gh0st42/core-helpers &&\
    cp core-helpers/bin/* /usr/local/bin &&\
    rm -rf core-helpers

# enable sshd
RUN mkdir /var/run/sshd &&  sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#X11UseLocalhost yes/X11UseLocalhost no/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV PASSWORD "netsim"
RUN echo "root:$PASSWORD" | chpasswd

ENV SSHKEY ""

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN mkdir -p /root/.core/myservices && mkdir -p /root/.coregui/custom_services
RUN sed -i 's/grpcaddress = localhost/grpcaddress = 0.0.0.0/g' /etc/core/core.conf

COPY update-custom-services.sh /update-custom-services.sh

EXPOSE 22
EXPOSE 50051


# ADD extra /extra
VOLUME /shared

COPY entryPoint.sh /root/entryPoint.sh
ENTRYPOINT "/root/entryPoint.sh"

