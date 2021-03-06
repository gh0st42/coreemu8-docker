#!/bin/sh

SHARED="/tmp/shared"
PLATFORM=$(uname)

if [ -n "$1" ]; then
    if [ "$PLATFORM" = "Darwin" ]; then
        SHARED=$(greadlink -f $1)
    else 
        SHARED=$(readlink -f $1)
    fi
    echo Using custom shared directory: $SHARED
else 
    echo Using default shared directory: $SHARED
fi

if [ "$PLATFORM" = "Darwin" ]; then
xhost + 127.0.0.1
docker run -it --rm \
    --name coreemu8 \
    -p 2000:22 \
    -p 50051:50051 \
    -v $SHARED:/shared \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_ADMIN \
    -e SSHKEY="`cat ~/.ssh/id_rsa.pub`" \
    -e DISPLAY=host.docker.internal:0 \
    --privileged \
    gh0st42/coreemu8
else
xhost +local:root
docker run -it --rm \
    --name coreemu8 \
    -p 2000:22 \
    -v $SHARED:/shared \
    -p 50052:50051 \
    --cap-add=NET_ADMIN \
    --cap-add=SYS_ADMIN \
    -e SSHKEY="`cat ~/.ssh/id_rsa.pub`" \
    -e DISPLAY \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    --privileged \
    gh0st42/coreemu8
fi
