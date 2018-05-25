set os variables via scipt e.g. download from openstack
additionaly set env for path to your key
packer build desired_file.json

wait and get a coffee

launch machine, log in and check if everything is up

for dockered mongo:
also check if telegraf.conf in /etc/telegraf/telegraf.conf

add telegraf to the docker group
sudo usermod -aG docker telegraf

sudo docker run -p 27017:27017 --name mongo_instance03 -d mongo-docker --port 27017 --dbpath /data/mongodb --bind_ip 0.0.0.0 --storageEngine wiredTiger


For the YCSB see:
https://github.com/mongodb-labs/YCSB/tree/master/ycsb-mongodb/mongodb