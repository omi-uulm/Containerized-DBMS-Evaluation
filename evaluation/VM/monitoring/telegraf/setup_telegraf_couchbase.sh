#!/bin/sh

#installation and setup script for couchbase monitoring

#check if this script is run as root
if [[ $USER != "root" ]]; then 
		echo "This script must be run as root!" 
		exit 1
fi 


#correct timezone

echo "Europe/Berlin" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata



#download telegraf

apt-get update -y

wget https://dl.influxdata.com/telegraf/releases/telegraf_0.13.1_amd64.deb
dpkg -i telegraf_0.13.1_amd64.deb

service telegraf stop

mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.tmp 

#define config params


config_filename="/etc/telegraf/telegraf.conf"

#influxdb endpoint
influxdb_endpoint="134.60.64.100"
#infludb database name, choose according to benchmark: bare, bare_docker, vm, vm_docker
influx_database="vm"

#reporting interval for telegraf metrics
reporting_interval="10s"

# couchbase credentials
couchbase_user="admin"
couchbase_password="topsecret"

#global tags, e.g. ycsb or couchbase (choosing the hostname meaningful makes additional tags unnecessary, e.g. ycsb-1, couchbase-1,...)
nodetype="couchbase"
# hiwi tag: alex, nico
hiwi="alex"



########### write new config file ##############

#tagging
echo '[global_tags]' >>  ${config_filename}
echo ' nodetype = "'${nodetype}'"' >>  ${config_filename}
echo ' hiwi = "'${hiwi}'"' >>  ${config_filename}


#agent
echo '[agent]' >>  ${config_filename}
echo ' # Default data collection interval for all inputs' >>  ${config_filename}
echo ' interval = "'${reporting_interval}'"' >>  ${config_filename}
echo ' round_interval = true' >>  ${config_filename}
echo ' metric_batch_size = 1000' >>  ${config_filename}
echo ' metric_buffer_limit = 10000' >>  ${config_filename}
echo ' collection_jitter = "0s"' >>  ${config_filename}
echo ' flush_jitter = "0s"' >>  ${config_filename}
echo ' debug = false' >>  ${config_filename}
echo ' quiet = false' >>  ${config_filename}
echo ' ## Override default hostname, if empty use os.Hostname()' >>  ${config_filename}
echo ' hostname = ""' >>  ${config_filename}
echo ' omit_hostname = false' >>  ${config_filename}

#infludb reporting
echo '[[outputs.influxdb]]' >>   ${config_filename}
echo '  urls = ["http://'${influxdb_endpoint}':8086"]' >>   ${config_filename}
echo '  database = "'${influx_database}'"' >>   ${config_filename}
echo '  precision = "s"' >>   ${config_filename}
echo '  retention_policy = "default"' >>   ${config_filename}
echo '  write_consistency = "any"' >>   ${config_filename}
echo '  timeout = "5s"' >>   ${config_filename}


#input plugins
#cpu
echo '[[inputs.cpu]]' >>   ${config_filename}
echo '  percpu = true' >>   ${config_filename}
echo '  totalcpu = true' >>   ${config_filename}
echo '  fielddrop = ["time_*"]' >>   ${config_filename}

#memory
echo '[[inputs.mem]]' >>   ${config_filename}

#disk I/O
echo '[[inputs.diskio]]' >>   ${config_filename}

#network
echo '[[inputs.net]]' >>   ${config_filename}
echo '[[inputs.netstat]]' >>   ${config_filename}

#kernel
echo '[[inputs.kernel]]' >>   ${config_filename}

#system
echo '[[inputs.system]]' >>   ${config_filename}

#couchbase
echo '[[inputs.couchbase]]' >>   ${config_filename}
echo '  servers = ["http://'${couchbase_user}':'${couchbase_password}'@localhost:8091"]' >>   ${config_filename}


#restart telegraf with new config file
service telegraf start


########### modify existing config file (not tested) ######################

#configure tags
#sed -i -e 's/^  \# dc = "us-east-1" \# will tag all metrics with dc=us-east-1 / c\nodetype = $nodetype' /etc/telegraf/telegraf.conf
#sed -i -e 's/^  \# rack = "1a" / c\hostname = $HOSTNAME' /etc/telegraf/telegraf.conf

#configure influxdb reporting

#sed -i -e 's/^  urls = ["http://localhost:8086"] \# required / c\urls = ["http://$influxdb_endpoint:8086"]' /etc/telegraf/telegraf.conf
#sed -i -e 's/^  database = "telegraf" \# required / c\database = "$database"' /etc/telegraf/telegraf.conf


#configure system metrics



#configure couchbase reporting


#sed -i -e 's/^\# [[inputs.couchbase]] c\ [[inputs.couchbase]]' /etc/telegraf/telegraf.conf
#sed -i -e 's/^\#   servers = ["http://localhost:8091"] / c\servers = ["http://$couchbase_user:couchbase_password@localhost:8091"]' /etc/telegraf/telegraf.conf


