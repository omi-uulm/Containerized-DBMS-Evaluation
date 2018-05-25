#!/bin/bash

set -e
/usr/bin/telegraf --config /etc/telegraf/telegraf.conf &
mongod --port 27017 -dbpath /data/mongodb --bind_ip 0.0.0.0 --storageEngine wiredTiger --wiredTigerCacheSizeGB 2
/usr/bin/mongod

exec "$@"
