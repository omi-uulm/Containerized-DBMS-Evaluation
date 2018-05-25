# Docker MongoDB
# Based on Ubuntu 16.04
# mongodb version 3.4.2

FROM ubuntu:16.04

RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

#Install
#RUN apt-get update && apt-get install -y apt-utils
RUN apt-get update && apt-get upgrade -y

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5

RUN echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list

ENV VERSION 3.6.3

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    mongodb-org=$VERSION \
    mongodb-org-server=$VERSION \
    mongodb-org-shell=$VERSION \
    mongodb-org-mongos=$VERSION \
    mongodb-org-tools=$VERSION

#create mongodb data directory
RUN mkdir -p /data/mongodb
# copy mongodb config
ADD ./mongod.conf /etc/mongod.conf

#export port to host
EXPOSE 27017

#set /usr/bin/mongod as dockerized entry-point application
ENTRYPOINT ["/usr/bin/mongod"]

# default command
# CMD ["mongod --port 27017 -dbpath /data/mongodb --bind_ip 0.0.0.0 --storageEngine wiredTiger"]