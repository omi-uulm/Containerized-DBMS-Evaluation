#!/bin/bash

# script for installing docker via packer
# installation via repository
VERSION="18.03.0~ce-0~ubuntu"

# install packages to use repository over HTTPS if not installed
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
software-properties-common

# add docker gpg key
curl -sL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# for ubuntu 16.04 for last stable version
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"

sudo apt-get update

apt-cache madison docker-ce

#install docker version 18.03.0~ce
sudo apt-get install -y docker-ce=$VERSION