#!/bin/sh
# Usage: ./build.sh context namespace image [version]
set -eu
image="$2/$3"
version="${4:-}"

docker build --pull --no-cache --tag "$image:latest" "$1/."
if [ -n "$version" ]; then
    docker tag "$image:latest" "$image:$version"
fi

docker push "$image:latest"
if [ -n "$version" ]; then
    docker push "$image:$version"
fi

docker images "$image"
