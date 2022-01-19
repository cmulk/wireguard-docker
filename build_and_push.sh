#!/bin/bash

docker build --pull -f Dockerfile.buster -t cmulk/wireguard-docker:buster .
docker build --pull -f Dockerfile.alpine -t cmulk/wireguard-docker:alpine .
docker build --pull -f Dockerfile.stretch -t cmulk/wireguard-docker:stretch .

docker push cmulk/wireguard-docker:alpine
docker push cmulk/wireguard-docker:buster
docker push cmulk/wireguard-docker:stretch


