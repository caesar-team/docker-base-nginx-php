#!/bin/sh
NAME_CONTAINER=base-nginx-php-test
docker stop $NAME_CONTAINER || true && docker rm $NAME_CONTAINER || true
docker run -d --name $NAME_CONTAINER -p 8080:8080 caesarteam/base-nginx-php