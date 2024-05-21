#!/bin/bash
#docker pull techcto/alpine-php-fpm-7.2:latest

export $(egrep -v '^#' .env | xargs)
args=("$@")

# tag-php(){
#     cd php/alpine/php-fpm-7.2
#     VERSION="${args[1]}"
#     git tag -a v${VERSION} -m "tag release"
#     git push --tags
# }

$*