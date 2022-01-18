#!/usr/bin/env bash

docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-jupyter-fixed -f cuda/fixed/bipca-jupyter.dockerfile  . > cuda/bipca-jupyter-fixed-build.log & \
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-jupyter-editable -f cuda/editable/bipca-jupyter.dockerfile  . > cuda/bipca-jupyter-editable-build.log & \
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-base-fixed -f cuda/fixed/bipca-base.dockerfile  . > cuda/bipca-base-fixed-build.log  & \
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-base-editable -f cuda/editable/bipca-base.dockerfile  . > cuda/bipca-base-editable-build.log &