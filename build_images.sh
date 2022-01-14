#!/usr/bin/env bash

docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-jupyter-fixed -f fixed/bipca-cuda-jupyter.dockerfile  . &
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-jupyter-editable -f editable/bipca-cuda-jupyter.dockerfile  . &

#!/usr/bin/env bash

docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-base-fixed -f fixed/bipca-cuda-base.dockerfile  . &
docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg UNAME=$(id -u -n) -t $(id -u -n):bipca-cuda-base-editable -f editable/bipca-cuda-base.dockerfile  . &