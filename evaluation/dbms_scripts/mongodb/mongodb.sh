#!/bin/bash

###############################################################################
# GLOBAL PARAMETERS
###############################################################################
declare -A IPS

OPTION="single_mongo" # OPTIONS: single_mongo, single_cluster, cluster

# declare as following IPS[host_name]="host_ip"
IPS[host_name]="134.60.64.93"

USER="ubuntu" # machine user, Default: Ubuntu
SSH_KEY="~/.ssh/georg_omistack.pem" # path to youre key

# mongodb parameters
VERSION="3.4.2"
STORAGE_ENGINE="wiredTiger"

# single_mongo parameters
# SINGLE="" # uncomment this if you use single_cluster

# cluster parameters
# MONGOS_SERVER="" # uncomment this if you are using cluster
# CONFIG_SERVER="" # uncomment this if you are using cluster

###############################################################################
# INITIALIZE MONGODB
###############################################################################

for k in "${!IPS[@]}"; do
    ssh-keygen -R $k
    ssh-keygen -R ${IPS[$k]}
    ssh-keyscan -H ${IPS[$k]} >> ~/.ssh/known_hosts
    ssh-keyscan -H $k >> ~/.ssh/known_hosts

    ssh -i $SSH_KEY $USER@${IPS[$k]} "sudo apt-key adv --keyserver \
        hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6; \
        echo \"deb [ arch=amd64 ] http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse\" \
        | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list; \
        sudo DEBIAN_FRONTEND=nointeractive apt-get update; \
        sudo DEBIAN_FRONTEND=nointeractive apt-get upgrade -y; \
        sudo echo 127.0.1.1 $k | sudo tee /etc/hosts; \
        sudo apt-get install -y \
        mongodb-org=$VERSION \
        mongodb-org-server=$VERSION \
        mongodb-org-shell=$VERSION \
        mongodb-org-mongos=$VERSION \
        mongodb-org-tools=$VERSION;
        sudo service mongod stop;"
done

###############################################################################
# SET UP MONGODB
###############################################################################

function single_mongo {
    MONGOD="mkdir -p mongod; \
        screen -dm bash -c 'mongod --port 27017 --dbpath ./mongod --bind_ip 0.0.0.0 \
        --storageEngine $STORAGE_ENGINE';"

    if [ ${#IPS[@]} -eq 1 ]; then
        KEYS=(${!IPS[@]})
        ssh -i $SSH_KEY $USER@${IPS[${KEYS[0]}]} $MONGOD
        echo "finished setting up mongod on ${IPS[${KEYS[0]}]}"
    else
        echo "ERROR: you can only set this up on one machine!"
        exit
    fi
}

function single_cluster {
    MAIN_NODE_IP=${IPS[$SINGLE]}

    LOCALIP=$(ssh -i $SSH_KEY $USER@$MAIN_NODE_IP "hostname -I | sed s/\ //")

    ssh -i $SSH_KEY $USER@$MAIN_NODE_IP "mkdir -p output configsvr mongod; \
    screen -dm bash -c 'mongod --configsvr --dbpath ./configsvr --bind_ip 0.0.0.0 \
    --port 27019 > ./output/config_stdout.txt 2> ./output/config_stderr.txt'; \
    screen -dm bash -c 'mongos --configdb $LOCALIP:27019 --bind_ip 0.0.0.0 \
    --port 27017 > ./output/mongos_stdout.txt 2> ./output/mongos_stderr.txt';"

    sleep 2

    echo "starting to add shards to cluster"

    for k in "${!IPS[@]}"; do
        NETWORKIP=$(ssh -i $SSH_KEY $USER@${IPS[$k]} "hostname -I | sed s/\ //")

        ssh -i $SSH_KEY $USER@${IPS[$k]} "mkdir -p mongod output; \
        screen -dm bash -c 'mongod --shardsvr --dbpath ./mongod --bind_ip 0.0.0.0 \
        --port 27018 > ./output/mongod_stdout.txt 2> ./output/mongod_stderr.txt';"

        sleep 2

        ssh -i $SSH_KEY $USER@$MAIN_NODE_IP "echo 'sh.addShard(\"$NETWORKIP:27018\")' \
        > add_shard.js; \
        mongo < ./add_shard.js;"
    done

    sleep 2

    ssh -i $SSH_KEY $USER@$MAIN_NODE_IP "echo -e 'use ycsb\ndb.createCollection(\"usertable\")\nsh.enableSharding(\"ycsb\")\nsh.shardCollection(\"ycsb.usertable\", {_id:1})' \
       > enable_sharding.js; \
       mongo < ./enable_sharding.js"

    echo "finished setting up sinle cluster on $MAIN_NODE_IP"
}

function cluster {
    CONFIG_IP=${IPS[$CONFIG_SERVER]}
    MONGOS_IP=${IPS[$MONGOS_SERVER]}

    CONFIG_NET=$(ssh -i $SSH_KEY $USER@$CONFIG_IP "hostname -I | sed s/\ //")

    unset IPS[$CONFIG_SERVER]
    unset IPS[$MONGOS_SERVER]

    # creating mongdb config server
    echo "creating config server"
    ssh -i $SSH_KEY $USER@$CONFIG_IP "mkdir -p configsvr output; \
    screen -dm bash -c 'mongod --configsvr --dbpath ./configsvr --bind_ip 0.0.0.0 \
    --port 27019 > ./output/config_stdout.txt 2> ./output/config_stderr.txt';"

    sleep 2

    # creating mongos
    echo "creating mongos instance"
    ssh -i $SSH_KEY $USER@$MONGOS_IP "mkdir -p output;
    screen -dm bash -c 'mongos --configdb $CONFIG_NET:27019 --bind_ip 0.0.0.0 \
    --port 27017 > ./output/mongos_stdout.txt 2> ./output/mongos_stderr.txt';"

    sleep 2

    # adding shards to cluster
    echo "starting to add shards to cluster"
    for k in "${!IPS[@]}"; do
        NETWORKIP=$(ssh -i $SSH_KEY $USER@${IPS[$k]} "hostname -I | sed s/\ //")

        ssh -i $SSH_KEY $USER@${IPS[$k]} "mkdir -p mongod output; \
        screen -dm bash -c 'mongod --shardsvr --dbpath ./mongod --bind_ip 0.0.0.0 \
        --port 27018 > ./output/mongod_stdout.txt 2> ./output/mongod_stderr.txt';"

        sleep 2

        ssh -i $SSH_KEY $USER@$MONGOS_IP "echo 'sh.addShard(\"$NETWORKIP:27018\")' \
        > add_shard.js; \
        mongo < ./add_shard.js;"
    done

    ssh -i $SSH_KEY $USER@$MONGOS_IP "echo -e 'use ycsb\ndb.createCollection(\"usertable\")\nsh.enableSharding(\"ycsb\")\nsh.shardCollection(\"ycsb.usertable\", {_id:1})' \
       > enable_sharding.js; \
       mongo < ./enable_sharding.js"

    echo "finished to setting up mongodb cluster, mongos instance is on: $MONGOS_IP"
}

case $OPTION in
    single_mongo)
        echo "starting setting up mongod instance!"
        single_mongo
        exit
        ;;
    single_cluster)
        echo "starting to setting up mongodb single_cluster on ${IPS[$SINGLE]}"
        single_cluster
        exit
        ;;
    cluster)
        if [ ${#IPS[@]} -eq 2 ]; then
            echo "you need atleast 3 machines"
        else
            echo "starting to setting up mongodb cluster"
            cluster
        fi
        exit
        ;;
    *)
        echo "you have to choose the right options"
        ;;
esac
