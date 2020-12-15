#!/usr/bin/env bash

base_dir=$(cd `dirname $0`/..; pwd)
jar_file=${base_dir}/target/nacos-server.jar
jars_dir=${base_dir}/target
properties_file=${base_dir}/nacos_conf/nacos.properties


check_dependency() {
    if ! command -v java > /dev/null; then
        echo " - Java is not installed [Error]" >&2
        exit 1
    fi
}

get_property_value() {
    properties_file=$1
    property_key=$2
    property=$(cat ${properties_file} | grep ${property_key} | grep -v '#')
    echo "${property#*=}"
}

set_property_value() {
    properties_file=$1
    property_key=$2
    property_value=$3
    property=^${property_key}.*
    if [ ${property_key} ]; then
        echo "$(sed "s|${property}|${property_key}=${property_value//\&/\\&}|g" ${properties_file})" > ${properties_file}
    fi
}

decrypt_value() {
    key=$1
    key_value=`get_property_value ${properties_file} ${key}`
    if [ -z "$key_value" ];then return; fi
    if echo ${key_value} | grep -E "^ENC\(.*\)$" > /dev/null 2>&1; then
        pw_decrypted=`java -cp ${jar_file} -Dloader.path="${jars_dir}" -Djava.security.egd=file:/dev/./urandom -Dloader.main=com.alibaba.nacos.config.server.utils.ConfigEncryptor org.springframework.boot.loader.PropertiesLauncher --decrypt "${key_value}"`
        echo ${pw_decrypted}
    else
        echo ${key_value}
    fi
}

check_dependency
decrypt_value 'spring.datasource.password'

