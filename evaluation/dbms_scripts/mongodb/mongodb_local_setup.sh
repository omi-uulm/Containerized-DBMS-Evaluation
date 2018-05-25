#!/bin/bash

# setup mongodb local
# single installation supported at the moment

OPTION="single_mongo" # OPTIONS: single_mongo

#mongodb parameters
VERSION="3.6.3"
STORAGE_ENGINE="wiredTiger"

sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
## for ubuntu 16_04
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" \
| sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list

sudo apt-get update
sudo apt-get upgrade -y
#sudo echo 127.0.1.1 $k | sudo tee /etc/hosts
sudo apt-get install -y \
mongodb-org=$VERSION \
mongodb-org-server=$VERSION \
mongodb-org-shell=$VERSION \
mongodb-org-mongos=$VERSION \
mongodb-org-tools=$VERSION

sudo systemctl stop mongod
sudo systemctl enable mongod

function single_mongo {
    mkdir -p mongod
    screen -dm bash -c 'mongod --port 27017 --dbpath ./mongod --bind_ip 0.0.0.0 --storageEngine $STORAGE_ENGINE'
}

case $OPTION in
    single_mongo)
        single_mongo
        ;;
    *)
        ;;
esac