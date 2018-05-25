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
ADD ./mongodb_attached_vol/mongod.conf /etc/mongod.conf

#export port to host
EXPOSE 27018

RUN apt-get install -y software-properties-common curl apt-transport-https
# telegeraf
RUN curl -sL https://repos.influxdata.com/influxdb.key | apt-key add -
RUN echo "deb https://repos.influxdata.com/ubuntu xenial stable" | tee /etc/apt/sources.list.d/influxdb.list

#download telegraf
RUN apt-get update -y
# install telegraf from apt
RUN apt-get install -y telegraf ntp

RUN mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.tmp
ADD ./mongodb_attached_vol/monitoring/mongodb_host_vol.conf /etc/telegraf/telegraf.conf

WORKDIR /opt
ADD ./mongodb_attached_vol/docker_entrypoint.sh /opt/entrypoint.sh
#TODO entrypoint
# start telegraf
#CMD ["/usr/bin/telegraf --config /etc/telegraf/telegraf.conf", "mongod --port 27017 -dbpath /data/mongodb --bind_ip 0.0.0.0 --storageEngine wiredTiger"]

#set /usr/bin/mongod as dockerized entry-point application
ENTRYPOINT ["/opt/entrypoint.sh"]

# default command
# CMD ["mongod --port 27017 -dbpath /data/mongodb --bind_ip 0.0.0.0 --storageEngine wiredTiger"]