#!/bin/bash

image_name="daniellindemann/do-ddns-update"

# Exit immediately if a command exits with a non-zero status
set -e

# Get script directory
script_dir=$(dirname "$0")

# add parameter for version
if [ -z "$1" ]; then
    echo "Error: Version for docker image must be provided as an argument."
    exit 1
fi
docker_image_version=$1

# check if second parameter is "push"
if [ "$2" = "push" ]; then
    push=true
else
    push=false
fi

# check if buildx builder exists
if ! docker buildx ls | grep -q "do-ddns-update-builder"; then
    docker buildx create \
        --name do-ddns-update-builder \
        --platform linux/amd64,linux/arm64 \
        --use
fi

# Build the Docker image
if [ "$push" = true ]; then
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t $image_name:latest \
        -t $image_name:$docker_image_version \
        -t $image_name:$docker_image_version-alpine \
        --push $script_dir/..
else
    docker buildx build \
        --platform linux/amd64,linux/arm64 \
        -t $image_name:latest \
        -t $image_name:$docker_image_version \
        -t $image_name:$docker_image_version-alpine \
        $script_dir/..
fi
