#!/bin/sh
NAME_CONTAINER=nginx-php-fpm-test
docker stop $NAME_CONTAINER || true && docker rm $NAME_CONTAINER || true
docker run -d --name $NAME_CONTAINER -p8080:8080 4xxi/nginx-php-fpm