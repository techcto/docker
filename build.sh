
#- IE: ./build.sh php/alpine/php-fpm-7.2 techcto alpine-php-fpm-7.2
IMAGE=$2/$3

docker build --tag $IMAGE:latest $1/.

if [ -n "$4" ]; then
  docker build --tag $IMAGE:$4 $1/.
else
  echo "No tag supplied"
fi

docker push $IMAGE:latest
if [ -n "$4" ]; then
  docker push $IMAGE:$4
else
  echo ""
fi

echo "After:"
docker images $IMAGE