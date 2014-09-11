#!/bin/bash
#set -x
. ../config/scaleone.properties

BASE_DIR=$PWD/..
INSTALL_PACKAGE_PATH=$BASE_DIR/packages

i=0
while [ $i -lt $resource_node_count ]
do
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "su - nova -c ssh-keygen"
	./scp_get.sh ${resource_IP[$i]} root ${resource_passwd[$i]} /var/lib/nova/.ssh/id_rsa.pub $INSTALL_PACKAGE_PATH/id_rsa.pub 
	cat $INSTALL_PACKAGE_PATH/id_rsa.pub >> $INSTALL_PACKAGE_PATH/authorized_keys
	i=`expr $i + 1`
done
i=0
while [ $i -lt $resource_node_count ]
do
	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/authorized_keys /var/lib/nova/.ssh/authorized_keys
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "echo \"StrictHostKeyChecking no\" > /var/lib/nova/.ssh/config &"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "chown -R nova:nova /var/lib/nova/.ssh > /dev/null 2>&1 &"
	i=`expr $i + 1`
done	