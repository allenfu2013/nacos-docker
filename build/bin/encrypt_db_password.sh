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
    property=$(cat ${properties_file} | grep ${property_key} | grep -v '^#')
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

encrypt_and_replace_sensitive_value() {
    key=$1
    key_value=`get_property_value ${properties_file} ${key}`
    if [ -z "$key_value" ];then return; fi
    if echo ${key_value} | grep -E "^ENC\(.*\)$" > /dev/null 2>&1; then
        echo "${key} is already encrypted, no need to encrypt again"
    else
        pw_encrypted=`java -cp ${jar_file} -Dloader.path="${jars_dir}" -Djava.security.egd=file:/dev/./urandom -Dloader.main=com.alibaba.nacos.config.server.utils.ConfigEncryptor org.springframework.boot.loader.PropertiesLauncher --encrypt "${key_value}"`
        pw_final="ENC(${pw_encrypted})"
        set_property_value ${properties_file} ${key} ${pw_final}
    fi
}

check_dependency
encrypt_and_replace_sensitive_value 'spring.datasource.password'

