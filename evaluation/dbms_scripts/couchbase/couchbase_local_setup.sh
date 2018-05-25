#!/bin/bash

###############################################################################
# GLOBAL PARAMETERS
###############################################################################
declare -A IPS

# declare as following IPS[host_name]="host_ip"
IPS[host_name]="host_ip"
IPS[host_name2]="host_ip2"

USER="ubuntu" # machine user, Default: Ubuntu
SSH_KEY="path_to_key" # path to youre key

# link to couchbase binary
BASE_BINARY="https://packages.couchbase.com/releases/5.0.1/couchbase-server-community_5.0.1-ubuntu16.04_amd64.deb"

# COUCHBASE PARAMETERS
BUCKET_NAME='default' # name of Bucket, Default: default
RAMSIZE=3000 # couchbase Ramsize
INDEXSIZE=500 # couchbase Indexsize
REPLICATION_FACTOR=0 # couchabse replication factor

# decide which node should be main node of cluster
MAIN_NODE="host_name"

CH_USER='admin' # couchbase admin
CH_PW='topsecret' # couchbase admin password

HOSTNAME=hostname -I
###############################################################################
#  INITIALIZE COUCHBASE
###############################################################################
#HOST_IP=$(hostname -I | cut -d'' -f1)
HOST_IP="127.0.0.1"

CLUSTER_INIT="/opt/couchbase/bin/couchbase-cli cluster-init -c $HOST_IP:8091 \
        --cluster-username=$CH_USER \
        --cluster-password=$CH_PW \
        --cluster-ramsize=$RAMSIZE \
        --cluster-index-ramsize=$INDEXSIZE \
        --services=data,index,query,fts"

sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

sudo apt-get install -y python-httplib2 chrpath lsof lshw sysstat net-tools numactl

#sudo echo 127.0.1.1 $k | sudo tee /etc/hosts
wget -O couchbase.deb $BASE_BINARY
mv couchbase.deb /tmp/couchbase.deb
sudo dpkg -i /tmp/couchbase.deb

sleep 4

exec $CLUSTER_INIT

CREATE_BUCKET="/opt/couchbase/bin/couchbase-cli bucket-create -c $HOST_IP:8091 \
        -u $CH_USER \
        -p $CH_PW \
        --bucket=$BUCKET_NAME \
        --bucket-type=couchbase \
        --bucket-ramsize=$RAMSIZE \
        --bucket-priority=high \
        --bucket-replica=$REPLICATION_FACTOR \
        --wait"

#just one youchbase server
exec $CREATE_BUCKET



