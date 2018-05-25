#!/bin/bash

# COUCHBASE PARAMETERS
BUCKET_NAME='default' # name of Bucket, Default: default
RAMSIZE=3000 # couchbase Ramsize
INDEXSIZE=500 # couchbase Indexsize
REPLICATION_FACTOR=0 # couchabse replication factor

# decide which node should be main node of cluster
MAIN_NODE="host_name"

CH_USER='admin' # couchbase admin
CH_PW='topsecret' # couchbase admin password

HOST_IP="127.0.0.1"

###############################################################################
#  INITIALIZE COUCHBASE
###############################################################################
CLUSTER_INIT="/opt/couchbase/bin/couchbase-cli cluster-init -c $HOST_IP:8091 \
        --cluster-username=$CH_USER \
        --cluster-password=$CH_PW \
        --cluster-ramsize=$RAMSIZE \
        --cluster-index-ramsize=$INDEXSIZE \
        --services=data,index,query,fts"

exec $CLUSTER_INIT
