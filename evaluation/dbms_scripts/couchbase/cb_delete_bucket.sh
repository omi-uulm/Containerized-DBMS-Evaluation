#!/bin/bash

###############################################################################
# GLOBAL PARAMETERS
###############################################################################
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
# RENEW COUCHBASE
###############################################################################
DELETE_BUCKET="/opt/couchbase/bin/couchbase-cli bucket-delete -c $HOST_IP:8091 \
    -u $CH_USER -p $CH_PW \
    --bucket=$BUCKET_NAME
"

echo "starting to delete bucket: $BUCKET_NAME"
exec $DELETE_BUCKET
