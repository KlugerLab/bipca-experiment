#!/bin/bash
apt-get update && \
    apt-get install libgomp1
mkdir -p ./Sanity
chown -R $DEFAULT_USER ./Sanity
git clone https://github.com/jmbreda/Sanity.git ./Sanity
cd ./Sanity/src
make
ln -s ./Sanity/bin/Sanity /usr/local/bin/Sanity