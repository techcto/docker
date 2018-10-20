
#- ./build.sh php/alpine/php-fpm-7.2 techcto alpine-php-fpm-7.2
# cd ../php/alpine/php-fpm-7.2
TAG=$2/$3
docker images $TAG
docker build --tag $TAG $1/.
mkdir -p input output
docker save $TAG > input/$3.tar
docker run -v $(pwd)/input:/input -v $(pwd)/output:/output -v /tmp -i myyk/docker-squash -i input/$3.tar -o output/$3.tar
cat output/$3.tar | docker load
ls -alh input/* && ls -alh output/*
docker push $TAG
docker images $TAG