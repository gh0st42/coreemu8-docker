#!/bin/sh

docker buildx build -t gh0st42/coreemu8 --platform linux/amd64,linux/arm64 --push .
