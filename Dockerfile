FROM centos:7

MAINTAINER Justin Davis "justindavis@utexas.edu"

RUN yum -y upgrade

RUN yum -y install bash java-1.8.0-openjdk-headless java-1.8.0-openjdk ca-certificates mysql-client util-linux initscripts openssh java-1.8.0-openjdk \
    && rpm -Uvh http://repo.rundeck.org/latest.rpm  \
    && yum clean all

#RUN yumdownloader --destdir= rundeck rundeck-config 

COPY rpms /rpms

# RUN yumdownloader --destdir=./rpms/ rundeck rundeck-config 

COPY . /app
WORKDIR /app

RUN useradd -d /var/lib/rundeck -s /bin/false rundeck
RUN chmod u+x ./run.sh

EXPOSE 4443 4440

CMD ./run.sh
