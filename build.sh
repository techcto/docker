
#- IE: ./build.sh php/alpine/php-fpm-7.2 techcto alpine-php-fpm-7.2
TAG=$2/$3

docker build --tag $TAG:latest $1/.

#Method 1
# mkdir -p input output
# docker save $TAG > input/$3.tar
# docker run -v $(pwd)/input:/input -v $(pwd)/output:/output -v /tmp -i myyk/docker-squash -i input/$3.tar -o output/$3.tar
# cat output/$3.tar | docker load
# ls -alh input/* && ls -alh output/*

#Method 2
docker save $TAG | docker run  -v /tmp -i myyk/docker-squash -t $TAG -verbose | docker load

echo "Before:"
docker images $TAG

docker push $TAG:latest

echo "After:"
docker images $TAG:latest