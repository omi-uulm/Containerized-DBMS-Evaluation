#!/bin/sh

#installation and setup script for mongodb monitoring

#check if this script is run as root
#if [[ $USER != "root" ]]; then 
#		echo "This script must be run as root!" 
#		exit 1
#fi

# add influx data repository

sudo curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
sudo source /etc/lsb-release
sudo echo "deb https://repos.influxdata.com/ubuntu xenial stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

#download telegraf

sudo apt-get update -y

#sudo wget https://dl.influxdata.com/telegraf/releases/telegraf_0.13.1_amd64.deb
#sudo dpkg -i telegraf_0.13.1_amd64.deb
# install telegraf from apt
sudo apt-get install -y telegraf ntp

#sudo service telegraf stop
# for systemd os's
sudo systemctl stop telegraf
sudo systemctl disable telegraf

sudo mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.tmp 

#restart telegraf with new config file
# sudo service telegraf start
