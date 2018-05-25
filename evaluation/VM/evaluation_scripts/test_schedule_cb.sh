#!/bin/bash

##############################
# test cases for couchbase db    #
##############################

# GLOBAL PARAMETER
declare -A IPS

## set variables
IPS[host_name]="192.168.0.139" # for vm only
IPS[host_name2]="192.168.0.153" # 192.168.0.241 for dockered version
AMOUNT_OF_TESTS=1 #set amount of test runs
USER="ubuntu"
SSH_KEY="/home/ubuntu/.ssh/db-bench-key"

## check if directory structure is created; missing directories will be added
## $1 threadcount, $2 IS_DOCKER
function checkDirectory {
    cd $HOME
    if [ ! -d "cb_ycsb_tests" ]; then
        mkdir "cb_ycsb_tests"
    fi
    cd ycsb_tests
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
}

## creates TestDirectory for timestamp in
## $1 threadcount, $2 TIMESTAMP, $3 IS_DOCKER
function createTestDirectory {
    cd $HOME
    if [ $3 = false ]; then
        if [ ! -d "cb_ycsb_tests/vm/${1}_threads/${2}" ]; then
            mkdir "cb_ycsb_tests/vm/${1}_threads/${2}"
        fi
    fi
    if [ $3 = true ]; then
        if [ ! -d "cb_ycsb_tests/dockered/${1}_threads/${2}" ]; then
            mkdir "cb_ycsb_tests/dockered/${1}_threads/${2}"
        fi
    fi
}

## renew database after each test
## $1 IP, $2 IS_DOCKER
function renewdb {
    if [ $2 = false ]; then
        ssh -i $SSH_KEY $USER@$1 "/home/ubuntu/db_scripts/couchbase/cb_delete_bucket.sh"
        sleep 10
        ssh -i $SSH_KEY $USER@$1 "/home/ubuntu/db_scripts/couchbase/cb_create_bucket.sh"
    fi
    if [ $2 = true ]; then
        # contaniername for Docker container
        CONTAINERNAME="cb_instance01"
        ssh -i $SSH_KEY $USER@$1 "docker exec -i ${CONTAINERNAME} ./cb_delete_bucket.sh"
        sleep 10
        ssh -i $SSH_KEY $USER@$1 "docker exec -i ${CONTAINERNAME} ./cb_create_bucket.sh"
        sleep 10
    fi
}

## set new environment vars
# $1 workload $2 iteration $3 sdocker? $4 ip
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
## $1 threadcount, $2 IP, $3 TESTPATH, $4 IS_DOCKER
function loadWorkload {
    cd ~/ycsb-0.12.0
    if [ $4 = false ]; then
            cat > /home/ubuntu/cb_scripts/couchbase/cb_vm.properties << EOL
couchbase.url=${2}:8091
couchbase.host=${2}
couchbase.bucket=default
couchbase.password=
couchbase.persistTo=0
couchbase.replicateTo=0
couchbase.json=true
EOL
        ./bin/ycsb load couchbase2 -s -p recordcount=2000000 -p operationcount=10000000 -threads $1 -P workloads/workloada -P /home/ubuntu/db_scripts/couchbase/cb_vm.properties > $HOME/${3}/load.txt 2>&1
    fi
    if [ $4 = true ]; then
                cat > /home/ubuntu/cb_scripts/couchbase/cb_docker.properties << EOL
couchbase.url=${2}:8091
couchbase.host=${2}
couchbase.bucket=default
couchbase.password=
couchbase.persistTo=0
couchbase.replicateTo=0
couchbase.json=true
EOL
        ./bin/ycsb load couchbase2 -s -p recordcount=2000000 -p operationcount=10000000 -threads $1 -P workloads/workloada -P /home/ubuntu/db_scripts/couchbase/cb_docker.properties > $HOME/${3}/load.txt 2>&1
    fi
}

## run workloadA
## read 50%
## update 50%
## $1 threadcount, $2 IP, $3 TESTPATH, $4 IS_DOCKER
function runWorkloadA {
    cd ~/ycsb-0.12.0
    if [ $4 = false ]; then
            cat > /home/ubuntu/cb_scripts/couchbase/cb_vm.properties << EOL
couchbase.url=${2}:8091
couchbase.host=${2}
couchbase.bucket=default
couchbase.password=
couchbase.persistTo=0
couchbase.replicateTo=0
couchbase.json=true
EOL
        ./bin/ycsb run couchbase2 -s -p recordcount=2000000 -p operationcount=10000000 -threads $1 -P workloads/workloada -P /home/ubuntu/db_scripts/couchbase/cb_vm.properties > $HOME/${3}/run_workloadA.txt 2>&1
    fi
    if [ $4 = true ]; then
                cat > /home/ubuntu/cb_scripts/couchbase/cb_docker.properties << EOL
couchbase.url=${2}:8091
couchbase.host=${2}
couchbase.bucket=default
couchbase.password=
couchbase.persistTo=0
couchbase.replicateTo=0
couchbase.json=true
EOL
        ./bin/ycsb run couchbase2 -s -p recordcount=2000000 -p operationcount=10000000 -threads $1 -P workloads/workloada -P /home/ubuntu/db_scripts/couchbase/cb_docker.properties > $HOME/${3}/run_workloadA.txt 2>&1
    fi
}

## run workloadB
## read 95%
## update 5%
## $1 threadcount, $2 IP, $3 TESTPATH, $4 IS_DOCKER
function runWorkloadB {
    cd ~/ycsb-0.12.0
    if [ $4 = false ]; then
        cat > /home/ubuntu/cb_scripts/couchbase/cb_vm.properties << EOL
couchbase.url=${2}:8091
couchbase.host=${2}
couchbase.bucket=default
couchbase.password=
couchbase.persistTo=0
couchbase.replicateTo=0
couchbase.json=true
EOL
        ./bin/ycsb run couchbase2 -s -p recordcount=2000000 -p operationcount=10000000 -threads $1 -P workloads/workloadb -P /home/ubuntu/db_scripts/couchbase/cb_vm.properties > $HOME/${3}/run_workloadB.txt 2>&1
    fi
    if [ $4 = true ]; then
            cat > /home/ubuntu/cb_scripts/couchbase/cb_docker.properties << EOL
couchbase.url=${2}:8091
couchbase.host=${2}
couchbase.bucket=default
couchbase.password=
couchbase.persistTo=0
couchbase.replicateTo=0
couchbase.json=true
EOL
        ./bin/ycsb run couchbase2 -s -p recordcount=2000000 -p operationcount=10000000 -threads $1 -P workloads/workloadb -P /home/ubuntu/db_scripts/couchbase/cb_docker.properties > $HOME/${3}/run_workloadB.txt 2>&1
    fi
}

## the main loop of this script
for k in "${!IPS[@]}"; do
    # is it vm ip
    if [ "${IPS[$k]}" == "192.168.0.139" ]; then
        IS_DOCKER=false
    fi
    # is it dockered ip
    if [ "${IPS[$k]}" == "192.168.0.153" ]; then
        IS_DOCKER=true
    fi

    # loop over amount of test runs
    for (( i=0; i<${AMOUNT_OF_TESTS}; i++ ))
    do
        # threadcounts loop and execute tests
        TIMESTAMP=$(date -d "today" +"%Y%m%d%H%M")
        for var in 8
	    do 
            checkDirectory "$var" $IS_DOCKER
            createTestDirectory "$var" "$TIMESTAMP" $IS_DOCKER
            if [ $IS_DOCKER = false ]; then
                TESTPATH="cb_ycsb_tests/vm/${var}_threads/${TIMESTAMP}"
            else
                TESTPATH="cb_ycsb_tests/dockered/${var}_threads/${TIMESTAMP}"
            fi
            set_environment_restart_telegraf "load" "$i" $IS_DOCKER "${IPS[$k]}"
            renewdb "${IPS[$k]}" $IS_DOCKER
            sleep 2
            loadWorkload "$var" "${IPS[$k]}" "$TESTPATH" $IS_DOCKER
            sleep 1m
            set_environment_restart_telegraf "workloadB" "$i" $IS_DOCKER "${IPS[$k]}"
            #runWorkloadA "$var" "${IPS[$k]}" "$TESTPATH" $IS_DOCKER
            #sleep 1m
            runWorkloadB "$var" "${IPS[$k]}" "$TESTPATH" $IS_DOCKER
            sleep 1m
        done 
    done

done
