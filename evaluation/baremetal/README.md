# set up testbed

Step 1: 
Download from git

download docker-compose
curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-Linux-x86_64 > docker-compose

Step 2:
run the pre-setup.sh script
```
./pre-setup.sh
```

Step 3: run docker-compose, wait for build. After building initialy, the conatiners should be up and running
```
docker-compose up -d
```

Step 4: start the intended test_schedule script
from ~/db-docker-vm-evaluation/baremetal/test_schedule
```
nohup ./test_schedule_baremetal_mognodb.sh 2>&1
```

Important information:
 * If there are any failures stop docke-compose and remove containers
 ```
 docker-compose stop && docker-compose rm -v
 ```
 * The collected data from the ycsb-container will be stored in attached volume, so the information is saved outside the ycsb container.
 ```
 /srv/test-results
 ```
