#!/bin/bash
#set -x
. ../config/scaleone.properties

BASE_DIR=$PWD/..
INSTALL_PACKAGE_PATH=$BASE_DIR/packages

rm -rf $INSTALL_PACKAGE_PATH/hosts
echo "127.0.0.1 localhost" > $INSTALL_PACKAGE_PATH/hosts

i=0
while [ $i -lt $resource_node_count ]
do
	echo "${resource_IP[$i]} ${resource_name[$i]}" >> $INSTALL_PACKAGE_PATH/hosts
	i=`expr $i + 1`
done
echo "::1     ip6-localhost ip6-loopback" >> $INSTALL_PACKAGE_PATH/hosts
echo "fe00::0 ip6-localnet" >> $INSTALL_PACKAGE_PATH/hosts
echo "ff00::0 ip6-mcastprefix" >> $INSTALL_PACKAGE_PATH/hosts
echo "ff02::1 ip6-allnodes" >> $INSTALL_PACKAGE_PATH/hosts
echo "ff02::2 ip6-allrouters" >> $INSTALL_PACKAGE_PATH/hosts

cat $INSTALL_PACKAGE_PATH/hosts
