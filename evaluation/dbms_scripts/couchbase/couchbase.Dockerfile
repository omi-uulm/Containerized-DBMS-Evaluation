# Docker Couchbase
# based on Ubuntu 14.04
# coucbase version 4.5.1

FROM ubuntu:14.04
#FROM ubuntu:16.04

RUN apt-get update && \
    apt-get install -y runit wget python-httplib2 chrpath lsof lshw sysstat net-tools numactl

#ubuntu 14.04 version
ARG CB_VERSION=5.0.1
ARG CB_RELEASE_URL=https://packages.couchbase.com/releases
# ubuntu 14.04 version
ARG CB_PACKAGE=couchbase-server-community_5.0.1-ubuntu16.04_amd64.deb

# Create Couchbase user with UID 1000 (necessary to match default
# boot2docker UID)
RUN groupadd -g 1000 couchbase && useradd couchbase -u 1000 -g couchbase -M

ENV PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

# Install couchbase
# echo "$CB_SHA256  $CB_PACKAGE" | sha256sum -c - && \
RUN wget -N $CB_RELEASE_URL/$CB_VERSION/$CB_PACKAGE && \
    dpkg -i ./$CB_PACKAGE && rm -f ./$CB_PACKAGE

RUN sleep 4

# Fix curl RPATH
RUN chrpath -r '$ORIGIN/../lib' /opt/couchbase/bin/curl

# Add runit script for couchbase-server
COPY cb_runit /etc/service/couchbase-server/run

# Add dummy script for commands invoked by cbcollect_info that
# make no sense in a Docker container
COPY dummy.sh /usr/local/bin/
RUN ln -s dummy.sh /usr/local/bin/iptables-save && \
    ln -s dummy.sh /usr/local/bin/lvdisplay && \
    ln -s dummy.sh /usr/local/bin/vgdisplay && \
    ln -s dummy.sh /usr/local/bin/pvdisplay

# Add bootstrap script
COPY cb_entrypoint.sh /entrypoint.sh
COPY cb_init.sh /cb_init.sh
COPY cb_delete_bucket.sh /cb_delete_bucket.sh
COPY cb_create_bucket.sh /cb_create_bucket.sh
RUN chmod 755 entrypoint.sh cb_init.sh cb_delete_bucket.sh cb_create_bucket.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["couchbase-server"]

# 8091: Couchbase Web console, REST/HTTP interface
# 8092: Views, queries, XDCR
# 8093: Query services (4.0+)
# 8094: Full-text Search (4.5+)
# 11207: Smart client library data node access (SSL)
# 11210: Smart client library/moxi data node access
# 11211: Legacy non-smart client library data node access
# 18091: Couchbase Web console, REST/HTTP interface (SSL)
# 18092: Views, query, XDCR (SSL)
# 18093: Query services (SSL) (4.0+)
EXPOSE 8091 8092 8093 8094 11207 11210 11211 18091 18092 18093
VOLUME /opt/couchbase/var