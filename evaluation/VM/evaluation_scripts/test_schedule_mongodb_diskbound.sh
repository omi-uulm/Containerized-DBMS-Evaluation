#!/bin/bash

##############################
# test cases for mongo db    #
##############################

# GLOBAL PARAMETER
declare -A IPS

## set variables
IPS[host_name]="10.1.1.13" # for vm only
IPS[host_name2]="10.1.1.11" # 192.168.0.241 for dockered version..
IPS[host_name3]="10.1.1.8" # dockered version with attached volume

#IS_DOCKER=false #set to true if mongodb is dockered? now automaticly set depending on the IP
AMOUNT_OF_TESTS=10 #set amount of test runs
USER="ubuntu"
SSH_KEY="/home/ubuntu/.ssh/db-bench-key"

## check if directory structure is created; missing directories will be added
## $1 threadcount, $2 IS_DOCKER, $3 HAS_ATTACHED_VOL
function checkDirectory {
    cd $HOME
    if [ ! -d "mongodb_ycsb_diskbound_tests" ]; then
        mkdir "mongodb_ycsb_diskbound_tests"
    fi
    cd mongodb_ycsb_diskbound_tests
    if [ $2 = false ]; then
        if [ ! -d "vm" ]; then
            mkdir "vm"
            mkdir "vm/plots"
	    touch "vm/plots/.empty"
        fi
        cd vm
        if [ ! -d "${1}_threads" ]; then
            mkdir "${1}_threads"
        fi
    # so dockered dir
    else
        if [ $3 = true ]; then
            if [ ! -d "dockered_attached_vol" ]; then
                mkdir "dockered_attached_vol"
                mkdir "dockered_attached_vol/plots"
	        touch "dockered_attached_vol/plots/.empty"
            fi
            cd dockered_attached_vol
            if [ ! -d "${1}_threads" ]; then
                mkdir "${1}_threads"
            fi
        else
            if [ ! -d "dockered" ]; then
                mkdir "dockered"
                mkdir "dockered/plots"
	        touch "dockered/plots/.empty"
            fi
            cd dockered
            if [ ! -d "${1}_threads" ]; then
                mkdir "${1}_threads"
            fi
        fi
    fi
}

## creates TestDirectory for timestamp in
## $1 threadcount, $2 TIMESTAMP, $3 IS_DOCKER, $4 HAS_ATTACHED_VOL
function createTestDirectory {
    cd $HOME
    if [ $3 = false ]; then
        if [ ! -d "mongodb_ycsb_diskbound_tests/vm/${1}_threads/${2}" ]; then
            mkdir "mongodb_ycsb_diskbound_tests/vm/${1}_threads/${2}"
        fi
    fi
    if [ $3 = true ]; then
        if [ $4 = true ]; then
            if [ ! -d "mongodb_ycsb_diskbound_tests/dockered_attached_vol/${1}_threads/${2}" ]; then
                mkdir "mongodb_ycsb_diskbound_tests/dockered_attached_vol/${1}_threads/${2}"
            fi
        else
            if [ ! -d "mongodb_ycsb_diskbound_tests/dockered/${1}_threads/${2}" ]; then
                mkdir "mongodb_ycsb_diskbound_tests/dockered/${1}_threads/${2}"
            fi
        fi
    fi
}

## renew database after each test
## $1 IP, $2 IS_DOCKER, $3 HAS_ATTACHED_VOL
function renewdb {
    if [ $2 = false ]; then
        ssh -i $SSH_KEY $USER@$1 "echo -e 'use ycsb\ndb.dropDatabase()' > delete.js; \
            mongo < ./delete.js;"
    fi
    if [ $2 = true ]; then
        # contaniername for Docker container
        CONTAINERNAME="mongo_instance01"
        MYCMD="echo -e 'use ycsb\ndb.dropDatabase()' > delete.js"
        ssh -i $SSH_KEY $USER@$1 "${MYCMD}; docker exec -i ${CONTAINERNAME} mongo < ./delete.js;"
    fi
}

## set new environment vars
# $1 workload $2 iteration $3 sdocker? $4 ip, $5 HAS_ATTACHED_VOL
# put it all into a ingle script, because the environment variable chenges are only visible to its process instance
function set_environment_restart_telegraf {
    WL="WORKLOAD=${1}"
    ER="EVALUATION_RUN=${2}"
    export "${WL}"
    export "${ER}"
    pkill -9 telegraf
    /usr/bin/telegraf --config /etc/telegraf/telegraf.conf 2>&1 &

    REMOTE_CMD="echo -e 'export ${ER}\nexport ${WL}\npkill -9 telegraf\n/usr/bin/telegraf --config /etc/telegraf/telegraf.conf 2>&1 &' > restart_telegraf.sh"
    ssh -i $SSH_KEY $USER@$4 "${REMOTE_CMD}; /bin/bash ./restart_telegraf.sh;" &
}

## load workload into databse
## $1 threadcount, $2 IP, $3 TESTPATH
function loadWorkload {
    cd ~/ycsb-0.12.0
    ./bin/ycsb load mongodb -s -threads $1 -P workloads/workloada -p recordcount=10000000 -p operationcount=10000000 -threads 8 -p mongodb.url="mongodb://${2}:27017/ycsb?w=1" > $HOME/${3}/load.txt 2>&1
}

## run workloadA
## read 50%
## update 50%
## $1 threadcount, $2 IP, $3 TESTPATH
function runWorkloadA {
    cd ~/ycsb-0.12.0
    ./bin/ycsb run mongodb -s -threads $1 -P workloads/workloada -p recordcount=10000000 -p operationcount=10000000 -threads 8 -p mongodb.url="mongodb://${2}:27017/ycsb?w=1" > $HOME/${3}/run_workloadA.txt 2>&1
}

## run workloadB
## read 95%
## update 5%
## $1 threadcount, $2 IP, $3 TESTPATH
function runWorkloadB {
    cd ~/ycsb-0.12.0
    ./bin/ycsb run mongodb -s -threads $1 -P workloads/workloadb -p recordcount=10000000 -p operationcount=10000000 -threads 8 -p mongodb.url="mongodb://${2}:27017/ycsb?w=1" > $HOME/${3}/run_workloadB.txt 2>&1
}

## the main loop of this script
for k in "${!IPS[@]}"; do
    # is it vm ip
    if [ "${IPS[$k]}" == "10.1.1.13" ]; then
        IS_DOCKER=false
        HAS_ATTACHED_VOL=false
    fi
    # is it dockered ip
    if [ "${IPS[$k]}" == "10.1.1.11" ]; then
        IS_DOCKER=true
        HAS_ATTACHED_VOL=false
    fi
    # is it with attached host vol
    if [ "${IPS[$k]}" == "10.1.1.8" ]; then
        IS_DOCKER=true
        HAS_ATTACHED_VOL=true
    fi

    # loop over amount of test runs
    for (( i=1; i<=${AMOUNT_OF_TESTS}; i++ ))
    do
        # threadcounts loop and execute tests
        TIMESTAMP=$(date -d "today" +"%Y%m%d%H%M")
        for var in 8
        do 
            checkDirectory "$var" $IS_DOCKER $HAS_ATTACHED_VOL
            createTestDirectory "$var" "$TIMESTAMP" $IS_DOCKER $HAS_ATTACHED_VOL
            if [ $IS_DOCKER = false ]; then
                TESTPATH="mongodb_ycsb_diskbound_tests/vm/${var}_threads/${TIMESTAMP}"
            else
                if [ $HAS_ATTACHED_VOL = true ]; then
                    TESTPATH="mongodb_ycsb_diskbound_tests/dockered_attached_vol/${var}_threads/${TIMESTAMP}"
                else
                    TESTPATH="mongodb_ycsb_diskbound_tests/dockered/${var}_threads/${TIMESTAMP}"
                fi
            fi
            set_environment_restart_telegraf "load" "$i" $IS_DOCKER "${IPS[$k]}" $HAS_ATTACHED_VOL
            renewdb "${IPS[$k]}" $IS_DOCKER $HAS_ATTACHED_VOL
            sleep 2
            loadWorkload "$var" "${IPS[$k]}" "$TESTPATH"
            sleep 1m
            set_environment_restart_telegraf "workloadB" "$i" $IS_DOCKER "${IPS[$k]}" $HAS_ATTACHED_VOL
            sleep 1m
            #runWorkloadA "$var" "${IPS[$k]}" "$TESTPATH"
            #sleep 2m
            runWorkloadB "$var" "${IPS[$k]}" "$TESTPATH"
            sleep 1m
        done 
    done

done
