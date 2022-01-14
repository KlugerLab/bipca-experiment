#!/usr/bin/env bash

docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-jupyter-fixed -f fixed/bipca-cuda-jupyter.dockerfile  . > bipca-cuda-jupyter-fixed-build.log & \
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-jupyter-editable -f editable/bipca-cuda-jupyter.dockerfile  . > bipca-cuda-jupyter-editable-build.log & \
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-base-fixed -f fixed/bipca-cuda-base.dockerfile  . > bipca-cuda-base-fixed-build.log  & \
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-base-editable -f editable/bipca-cuda-base.dockerfile  . > bipca-cuda-base-editable-build.log &