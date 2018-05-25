#!/bin/bash

##############################
# test cases for mongo db    #
# diskbound workload         #
##############################

# GLOBAL PARAMETER
declare -A IPS

## set variables
#IPS[host_name]="10.1.1.11" # for vm only
#IPS[host_name2]="10.1.1.12" # 192.168.0.241 for dockered version..
IPS[host_name3]="10.1.1.13" # dockered version with attached volume

#IS_DOCKER=false #set to true if mongodb is dockered? now automaticly set depending on the IP
AMOUNT_OF_TESTS=10 #set amount of test runs
USER="ubuntu"
SSH_KEY="/home/ubuntu/.ssh/db-bench-key"

## check if directory structure is created; missing directories will be added
## $1 threadcount, $2 IS_DOCKER, $3 HAS_ATTACHED_VOL
function checkDirectory {
    docker cp check_diskbound_directory.sh ycsb_vm:/opt/check_diskbound_directory.sh
    docker exec -i ycsb_vm /bin/bash -c "./check_diskbound_directory.sh $1 $2 $3"
}

## creates TestDirectory for timestamp in
## $1 threadcount, $2 TIMESTAMP, $3 IS_DOCKER, $4 HAS_ATTACHED_VOL
function createTestDirectory {
    docker cp create_diskbound_test_directory.sh ycsb_vm:/opt/create_diskbound_test_directory.sh
    docker exec -i ycsb_vm /bin/bash -c "./create_diskbound_test_directory.sh $1 $2 $3 $4"
}

## renew database after each test
## $1 IP, $2 IS_DOCKER, $3 HAS_ATTACHED_VOL
function renewdb {
    if [ $2 = false ]; then
        ssh -i $SSH_KEY $USER@$1 "echo -e 'use ycsb\ndb.dropDatabase()' > delete.js; \
            mongo < ./delete.js;"
    fi
    if [ $2 = true ]; then
        if [ $3 = true ]; then
            # contaniername for Docker container
            CONTAINERNAME="mongo_instance_host_vol"
        else
            CONTAINERNAME="mongo_instance_docker"
        fi
        echo -e 'use ycsb\ndb.dropDatabase()' > delete.js
        docker exec -i ${CONTAINERNAME} mongo < ./delete.js &
    fi
}

## set new environment vars
# $1 workload $2 iteration $3 sdocker? $4 ip, $5 HAS_ATTACHED_VOL
# put it all into a ingle script, because the environment variable chenges are only visible to its process instance
function set_environment_restart_telegraf {
    WL="WORKLOAD=${1}"
    ER="EVALUATION_RUN=${2}"
    #export "${WL}"
    #export "${ER}"
    # because there is no telegraf on baremetal
    #pkill -9 telegraf
    #/usr/bin/telegraf --config /etc/telegraf/telegraf.conf 2>&1 &

    echo -e 'export ${ER}\nexport ${WL}\npkill -9 telegraf\n/usr/bin/telegraf --config /etc/telegraf/telegraf.conf 2>&1 &' > restart_telegraf.sh

    if [ $3 == true ]; then
      if [ $5 == true ]; then
        CONTAINERNAME="mongo_instance_host_vol"
      else
        CONTAINERNAME="mongo_instance_docker"
      fi
    fi

    docker exec -i ${CONTAINERNAME} /bin/bash < ./restart_telegraf.sh
}

## load workload into databse
## $1 threadcount, $2 IP, $3 TESTPATH
function loadWorkload {
    if [ $4 == true ]; then
      if [ $5 == true ]; then
        CONTAINERNAME="mongo_instance_host_vol"
        MONGO_PORT="27018"
      else
        CONTAINERNAME="mongo_instance_docker"
        MONGO_PORT="27017"          
      fi
    fi
    echo -e "cd /opt/ycsb-0.12.0\n./bin/ycsb load mongodb -s -threads $1 -P workloads/workloada -p recordcount=10000000 -p operationcount=10000000 -threads 8 -p mongodb.url='mongodb://127.0.0.1:${MONGO_PORT}/ycsb?w=1' > /opt/test_results/${3}/load.txt 2>&1" > load_workload.sh

    docker exec -i ycsb_vm /bin/bash < load_workload.sh
}

## run workloadA
## read 50%
## update 50%
## $1 threadcount, $2 IP, $3 TESTPATH, $4 isdocker, $5 HAS_ATTACHED_VOL
function runWorkloadA {
    if [ $4 == true ]; then
      if [ $5 == true ]; then
        CONTAINERNAME="mongo_instance_host_vol"
        MONGO_PORT="27018"
      else
        CONTAINERNAME="mongo_instance_docker"
        MONGO_PORT="27017"
      fi
    fi
    echo -e "cd /opt/ycsb-0.12.0\n./bin/ycsb run mongodb -s -threads $1 -P workloads/workloada -p recordcount=10000000 -p operationcount=10000000 -threads 8 -p mongodb.url='mongodb://127.0.0.1:${MONGO_PORT}/ycsb?w=1' > /opt/test_results/${3}/run_workloadA.txt 2>&1" > run_workloadA.sh

    docker exec -i ycsb_vm /bin/bash < ./run_workloadA.sh
}

## run workloadB
## read 95%
## update 5%
## $1 threadcount, $2 IP, $3 TESTPATH, $4 isdocker, $5 HAS_ATTACHED_VOL
function runWorkloadB {
    if [ $4 == true ]; then
      if [ $5 == true ]; then
        CONTAINERNAME="mongo_instance_host_vol"
        MONGO_PORT="27018"
      else
        CONTAINERNAME="mongo_instance_docker"
        MONGO_PORT="27017"
      fi
    fi

    echo -e "cd /opt/ycsb-0.12.0\n./bin/ycsb run mongodb -s -threads $1 -P workloads/workloadb -p recordcount=10000000 -p operationcount=10000000 -threads 8 -p mongodb.url='mongodb://127.0.0.1:${MONGO_PORT}/ycsb?w=1' > /opt/test_results/${3}/run_workloadB.txt 2>&1" > run_workloadB.sh

    docker exec -i ycsb_vm /bin/bash < run_workloadB.sh
}

## the main loop of this script
for k in "${!IPS[@]}"; do
    # is it vm ip
    if [ "${IPS[$k]}" == "10.1.1.11" ]; then
        IS_DOCKER=false
        HAS_ATTACHED_VOL=false
    fi
    # is it dockered ip
    if [ "${IPS[$k]}" == "10.1.1.12" ]; then
        IS_DOCKER=true
        HAS_ATTACHED_VOL=false
    fi
    # is it with attached host vol
    if [ "${IPS[$k]}" == "10.1.1.13" ]; then
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
            cd /home/core/db-docker-vm-evaluation/baremetal
            ./docker-compose up -d
            cd /home/core/db-docker-vm-evaluation/baremetal/test_schedule
            sleep 1m
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
            #not for baremetal
            #set_environment_restart_telegraf "load" "$i" $IS_DOCKER "${IPS[$k]}" $HAS_ATTACHED_VOL
            #renewdb "${IPS[$k]}" $IS_DOCKER $HAS_ATTACHED_VOL
            sleep 2
            loadWorkload "$var" "${IPS[$k]}" "$TESTPATH" $IS_DOCKER $HAS_ATTACHED_VOL
            sleep 1m
            #not for baremetal 
            #set_environment_restart_telegraf "workloadB" "$i" $IS_DOCKER "${IPS[$k]}" $HAS_ATTACHED_VOL
            #sleep 1m
            #runWorkloadA "$var" "${IPS[$k]}" "$TESTPATH" $IS_DOCKER $HAS_ATTACHED_VOL
            #sleep 2m
            runWorkloadB "$var" "${IPS[$k]}" "$TESTPATH" $IS_DOCKER $HAS_ATTACHED_VOL
            sleep 1m
            cd /home/core/db-docker-vm-evaluation/baremetal
            ./docker-compose stop && ./docker-compose rm -f
            cd /srv/mongodb-storage
            sudo rm -rf *
            cd /home/core/db-docker-vm-evaluation/baremetal/test_schedule
            sleep 1m 
        done 
    done

done
