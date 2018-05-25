#!/bin/bash
cd /opt/test_results/
if [ $3 = false ]; then
    if [ ! -d "mongodb_ycsb_tests/vm/${1}_threads/${2}" ]; then
        mkdir "mongodb_ycsb_tests/vm/${1}_threads/${2}"
    fi
fi
if [ $3 = true ]; then
    if [ $4 = true ]; then
        if [ ! -d "mongodb_ycsb_tests/dockered_attached_vol/${1}_threads/${2}" ]; then
            mkdir "mongodb_ycsb_tests/dockered_attached_vol/${1}_threads/${2}"
        fi
    else
        if [ ! -d "mongodb_ycsb_tests/dockered/${1}_threads/${2}" ]; then
            mkdir "mongodb_ycsb_tests/dockered/${1}_threads/${2}"
        fi
    fi
fi