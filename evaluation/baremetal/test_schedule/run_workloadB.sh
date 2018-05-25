cd /opt/ycsb-0.12.0
./bin/ycsb run mongodb -s -threads 8 -P workloads/workloadb -p recordcount=10000000 -p operationcount=10000000 -threads 8 -p mongodb.url='mongodb://127.0.0.1:27017/ycsb?w=1' > /opt/test_results/mongodb_ycsb_diskbound_tests/dockered/8_threads/201804301151/run_workloadB.txt 2>&1
