FROM centos:7.5.1804
MAINTAINER pader "huangmnlove@163.com"

# set environment
ENV MODE="cluster" \
    PREFER_HOST_MODE="ip"\
    BASE_DIR="/home/nacos" \
    CLASSPATH=".:/home/nacos/conf:$CLASSPATH" \
    CLUSTER_CONF="/home/nacos/conf/cluster.conf" \
    FUNCTION_MODE="all" \
    JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk" \
    NACOS_USER="nacos" \
    JAVA="/usr/lib/jvm/java-1.8.0-openjdk/bin/java" \
    JVM_XMS="2g" \
    JVM_XMX="2g" \
    JVM_XMN="1g" \
    JVM_MS="128m" \
    JVM_MMS="320m" \
    NACOS_DEBUG="n" \
    TOMCAT_ACCESSLOG_ENABLED="false" \
    TIME_ZONE="Asia/Shanghai"

ARG NACOS_VERSION=1.3.1

WORKDIR /$BASE_DIR

RUN set -x \
    && yum update -y \
    && yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel wget iputils nc  vim libcurl \
    && rpm -ivh https://repo.mysql.com//mysql57-community-release-el7-11.noarch.rpm \
    && yum install -y mysql-community-client.x86_64
RUN wget https://fengjinghuadev.s3.cn-northwest-1.amazonaws.com.cn/kycloud/3.x/nacos/nacos_prd_0908/nacos-server-${NACOS_VERSION}.tar.gz -P /home
RUN tar -xzvf /home/nacos-server-${NACOS_VERSION}.tar.gz -C /home \
    && rm -rf /home/nacos-server-${NACOS_VERSION}.tar.gz /home/nacos/bin/* /home/nacos/conf/*.properties /home/nacos/conf/*.example
RUN yum autoremove -y wget \
    && ln -snf /usr/share/zoneinfo/$TIME_ZONE /etc/localtime && echo $TIME_ZONE > /etc/timezone \
    && yum clean all



ADD bin/docker-startup.sh bin/docker-startup.sh
ADD conf/application.properties conf/application.properties
ADD init.d/custom.properties init.d/custom.properties


# set startup log dir
RUN mkdir -p logs \
	&& cd logs \
	&& touch start.out \
	&& ln -sf /dev/stdout start.out \
	&& ln -sf /dev/stderr start.out

RUN chmod +x bin/docker-startup.sh

RUN addr_array=(`echo $NACOS_SERVERS | tr ':8848' ' '` ) \
    && cloud_addr=${addr_array[0]}${addr_array[1]} \
    && sed -i "1 i\nacos.kc.addresses=${cloud_addr}" conf/application.properties

RUN sed -i '1 i\SET tx_isolation="serializable";' conf/nacos-mysql.sql \
    && sed -i '1 i\begin;CREATE DATABASE IF NOT EXISTS nacos;USE nacos;'  conf/nacos-mysql.sql \
    && sed -i '$a\rollback;' conf/nacos-mysql.sql \
    && sed -i '$a\commit;' conf/nacos-mysql.sql

RUN sed -i '2 i\nohup mysql -u${MYSQL_SERVICE_USER} -h ${MYSQL_SERVICE_HOST} \
-p${MYSQL_SERVICE_PASSWORD} <${BASE_DIR}/conf/nacos-mysql.sql > /home/nacos/logs/mysql.log 2>&1 &' ${BASE_DIR}/bin/docker-startup.sh

EXPOSE 8848
ENTRYPOINT ["bin/docker-startup.sh"]
