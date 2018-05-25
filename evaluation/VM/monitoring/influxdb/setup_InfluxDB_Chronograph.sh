#!/bin/bash

##############################
# PARAMETERS                 #
##############################
CONFIG_PATH="" #e.g. /etc/influxdb/influxdb.conf



##############################
# SETUP INFLUXDB             #
# for ubuntu 14.04 (trusty)  #
##############################

#check if this script is run as root
if [[ $USER != "root" ]]; then
		echo "This script must be run as root!"
		exit 1
fi

#correct timezone

echo "Europe/Berlin" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata


apt-get update -y

# install influxDB

wget https://dl.influxdata.com/influxdb/releases/influxdb_1.5.1_amd64.deb
sudo dpkg -i influxdb_1.5.1_amd64.deb

# configure influxDB

# start InfluxDB
sudo systemctl start influxdb


# install chronograf

wget https://dl.influxdata.com/chronograf/releases/chronograf_1.4.3.1_amd64.deb
sudo dpkg -i chronograf_1.4.3.1_amd64.deb

# configure chronograf

# start chronograf
sudo systemctl start chronograf

echo "Installation successful! No authorization for InfluxDB and Chronograf enabled!"
