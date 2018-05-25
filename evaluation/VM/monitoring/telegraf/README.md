# Telegraf monitoring agent

Telegraf reports system metrics into InfluxDB

Docs: [https://influxdata.com/time-series-platform/telegraf/](https://influxdata.com/time-series-platform/telegraf/)

# Supported OS

only tested on Ubuntu 14.04

# Configuration

- copy setup\_telegraf\_couchbase.sh or setup\_telegraf\_ycsb.sh to target host

- InfluxDB endpoint is already configured
- 
- change at **influx_database** to the according benchmark:
	- couchbase node: couchbase\_vm, couchbase\_bare, couchbase\_vm\_docker, couchbase\_bare\_docker
	- ycsb node: ycsb_1, ...
	- for couchbase reporting change the couchbase credential vars accordingly, default: user=admin and password=topsecret
	- change the hiwi tag accordingly
	- change the nodetype accordingly
	- use meaningful hostname as the hostname is a default tag (e.g. ycsb-1, couchbase-bare,...)

# Installation

- run setup\_telegraf\_couchbase.sh or setup\_telegraf\_ycsb.sh

- telegraf will be started automatically

#Config file 

Ubuntu/Debian:

/etc/telegraf/telegraf.conf

# Logs

- /var/logs/telegraf

# Manuel testing 

telegraf -config telegraf.conf -test

# Monitoring Docker with telegraf



- currently not activated
- Blog post of the Couchbase developers: [https://blog.codeship.com/monitoring-docker-containers/?utm_campaign=Weekly%20Newsletters&utm_content=monitoring%25docker%20containers&utm_medium=newsletter&utm_source=email&utm_campaign=Weekly+Newsletters&utm_source=hs_email&utm_medium=email&utm_content=32351103&_hsenc=p2ANqtz--B8Y2zj7CbopAJkHHBZJsf6H5w68V8dAJncn0AHYRYE2h7JtWThX8wCAfov0AhX4XEvFToE1G4CLLTul9X1y86nvx10Ac3oa9vQtkn3TMbEyCtm_I&_hsmi=32347524](https://blog.codeship.com/monitoring-docker-containers/?utm_campaign=Weekly%20Newsletters&utm_content=monitoring%25docker%20containers&utm_medium=newsletter&utm_source=email&utm_campaign=Weekly+Newsletters&utm_source=hs_email&utm_medium=email&utm_content=32351103&_hsenc=p2ANqtz--B8Y2zj7CbopAJkHHBZJsf6H5w68V8dAJncn0AHYRYE2h7JtWThX8wCAfov0AhX4XEvFToE1G4CLLTul9X1y86nvx10Ac3oa9vQtkn3TMbEyCtm_I&_hsmi=32347524)
- telegraf docker plugin: [https://github.com/influxdata/telegraf/tree/master/plugins/inputs/docker](https://github.com/influxdata/telegraf/tree/master/plugins/inputs/docker)



