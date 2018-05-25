FROM ubuntu:16.04


# ycsb
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:webupd8team/java
RUN add-apt-repository -y universe
RUN apt-get update && apt-get upgrade -y
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections
RUN apt-get install -y oracle-java8-installer
RUN apt-get install -y git
RUN apt-get install -y maven
RUN apt-get install -y python curl apt-transport-https
WORKDIR /opt
RUN curl -O --location https://github.com/brianfrankcooper/YCSB/releases/download/0.12.0/ycsb-0.12.0.tar.gz
RUN tar xfvz ycsb-0.12.0.tar.gz

# telegeraf
RUN curl -sL https://repos.influxdata.com/influxdb.key | apt-key add -
RUN echo "deb https://repos.influxdata.com/ubuntu xenial stable" | tee /etc/apt/sources.list.d/influxdb.list

#download telegraf
RUN apt-get update -y
# install telegraf from apt
RUN apt-get install -y telegraf ntp

RUN mv /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.tmp
ADD ./monitoring/ycsb.conf /etc/telegraf/telegraf.conf

RUN mkdir test_results

#TODO entrypoint
#telegraf
# /usr/bin/telegraf --config /etc/telegraf/telegraf.conf
CMD /usr/bin/telegraf --config /etc/telegraf/telegraf.conf