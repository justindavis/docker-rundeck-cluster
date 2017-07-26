FROM centos:7

MAINTAINER Justin Davis "justindavis@utexas.edu"

RUN yum -y upgrade && yum clean all

RUN rpm -Uvh http://repo.rundeck.org/latest.rpm  \
    && rpm -Uvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-10.noarch.rpm \
    && yum -y --nogpgcheck install bash java-1.8.0-openjdk-headless java-1.8.0-openjdk ca-certificates mysql-client \
        util-linux initscripts openssh java-1.8.0-openjdk git ansible curl \
    && yum clean all

# RUN yumdownloader --destdir= rundeck rundeck-config 

# COPY rpms /rpms

RUN yumdownloader --destdir=/rpms/ rundeck rundeck-config 

COPY . /app
WORKDIR /app
ADD https://github.com/Batix/rundeck-ansible-plugin/releases/download/2.0.2/ansible-plugin-2.0.2.jar .

# RUN useradd -d /var/lib/rundeck -s /bin/false rundeck
RUN chmod u+x ./run.sh

EXPOSE 4443 4440

CMD ./run.sh
