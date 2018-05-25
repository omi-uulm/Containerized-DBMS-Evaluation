#!/bin/bash
cd /opt/test_results
if [ ! -d "mongodb_ycsb_tests" ]; then
    mkdir "mongodb_ycsb_tests"
fi
cd mongodb_ycsb_tests
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