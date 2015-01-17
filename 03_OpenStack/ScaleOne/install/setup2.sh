#!/bin/bash
#set -x
echo "确保正确配置了config目录下scaleone.properties文件中的参数(y/n):"
read test
if [ "n" = $test ]; then  
    exit 1  
fi  
. ../config/scaleone.properties

BASE_DIR=$PWD/..
INSTALL_PACKAGE_PATH=$BASE_DIR/packages

if [ "yes" = $ifvirtual ]; then  
#配网络
ifconfig br0:0 10.0.0.254 netmask 255.255.255.0 up
echo "create db_node"
mkdir -p /opt/db_node
cp $INSTALL_PACKAGE_PATH/ubuntu.img /opt/db_node
cp $INSTALL_PACKAGE_PATH/libvirt_db.xml /opt/db_node
sed -i "s%^ControlServAddr=.*$%ControlServAddr=$virtual_ctrl_IP%g" $INSTALL_PACKAGE_PATH/openstack_install.sh
sed -i "s%^DBServer=.*$%DBServer=$virtual_db_IP%g" $INSTALL_PACKAGE_PATH/openstack_install.sh
sed -i "s%mysql -u root -p %mysql -uroot -pintple %g" $INSTALL_PACKAGE_PATH/openstack_install.sh 
virsh create /opt/db_node/libvirt_db.xml
sed -i "s%^address.*$%address $virtual_db_IP%g" $BASE_DIR/config/interfaces_db 
sed -i "s%^netmask.*$%netmask $virtual_db_netmask%g" $BASE_DIR/config/interfaces_db 
sed -i "s%^gateway.*$%gateway $virtual_db_gateway%g" $BASE_DIR/config/interfaces_db 
sleep 90
./scp_file.sh 10.0.0.200 root intple $BASE_DIR/config/interfaces_db /etc/network/interfaces
./ssh_exec.sh 10.0.0.200 root intple "/etc/init.d/networking restart &" &

echo "create ctrl_node"
mkdir -p /opt/no_db_ctrl
cp $INSTALL_PACKAGE_PATH/ubuntu.img /opt/no_db_ctrl
cp $INSTALL_PACKAGE_PATH/libvirt_ctrl.xml /opt/no_db_ctrl
virsh create /opt/no_db_ctrl/libvirt_ctrl.xml
sed -i "s%^address.*$%address $virtual_ctrl_IP%g" $BASE_DIR/config/interfaces_ctrl
sed -i "s%^netmask.*$%netmask $virtual_ctrl_netmask%g" $BASE_DIR/config/interfaces_ctrl 
sed -i "s%^gateway.*$%gateway $virtual_ctrl_gateway%g" $BASE_DIR/config/interfaces_ctrl 
sleep 90
./scp_file.sh 10.0.0.200 root intple $BASE_DIR/config/interfaces_ctrl /etc/network/interfaces
./ssh_exec.sh 10.0.0.200 root intple "/etc/init.d/networking restart &" &
echo "virsh create /opt/db_node/libvirt_db.xml;sleep 30;virsh create /opt/no_db_ctrl/libvirt_ctrl.xml" >> /etc/rc.local
virpasswd=intple
sleep 10
ifconfig br0:0 down

else
	virpasswd=$mastnodepasswd
	virtual_db_IP=$mastnodeIP
	virtual_ctrl_IP=$mastnodeIP
fi

./scp_file.sh $virtual_db_IP root $virpasswd $INSTALL_PACKAGE_PATH/openstack_install.sh /root/openstack_install.sh
./scp_file.sh $virtual_db_IP root $virpasswd $BASE_DIR/config/scaleone.properties /root/scaleone.properties
./scp_file.sh $virtual_db_IP root $virpasswd $INSTALL_PACKAGE_PATH/CreateTable.sql /home/intple/CreateTable.sql
./scp_file.sh $virtual_db_IP root $virpasswd $INSTALL_PACKAGE_PATH/openstack.iso /root/openstack.iso
./scp_file.sh $virtual_db_IP root $virpasswd $INSTALL_PACKAGE_PATH/alarm.tar.gz /home/intple/alarm.tar.gz
./scp_file.sh $virtual_db_IP root $virpasswd $INSTALL_PACKAGE_PATH/scaleone_monitor.tar /opt/scaleone_monitor.tar
./scp_file.sh $virtual_db_IP root $virpasswd $BASE_DIR/install/virtual_db.sh /root/virtual_db.sh
./ssh_exec.sh $virtual_db_IP root $virpasswd "/root/openstack_install.sh db"
./ssh_exec.sh $virtual_db_IP root $virpasswd "/root/virtual_db.sh"

sleep 10
./scp_file.sh $virtual_ctrl_IP root $virpasswd $INSTALL_PACKAGE_PATH/openstack_install.sh /root/openstack_install.sh
./scp_file.sh $virtual_ctrl_IP root $virpasswd $BASE_DIR/config/scaleone.properties /root/scaleone.properties
./scp_file.sh $virtual_ctrl_IP root $virpasswd $INSTALL_PACKAGE_PATH/openstack.iso /root/openstack.iso
./scp_file.sh $virtual_ctrl_IP root $virpasswd $BASE_DIR/install/virtual_ctrl.sh /root/virtual_ctrl.sh
./scp_file.sh $virtual_ctrl_IP root $virpasswd $INSTALL_PACKAGE_PATH/alarm.tar.gz /home/intple/alarm.tar.gz
./scp_file.sh $virtual_ctrl_IP root $virpasswd $BASE_DIR/install/virtual_ctrl.sh /root/virtual_ctrl.sh
./scp_file.sh $virtual_ctrl_IP root $virpasswd $INSTALL_PACKAGE_PATH/scaleone.tar.gz /opt/scaleone.tar.gz
./scp_file.sh $virtual_ctrl_IP root $virpasswd $INSTALL_PACKAGE_PATH/scaleone_monitor.tar /opt/scaleone_monitor.tar
./ssh_exec.sh $virtual_ctrl_IP root $virpasswd "/root/virtual_ctrl.sh"

echo "ctrl node completed"
rm -rf $INSTALL_PACKAGE_PATH/authorized_keys
rm -rf $INSTALL_PACKAGE_PATH/hosts
echo "127.0.0.1 localhost" > $INSTALL_PACKAGE_PATH/hosts
i=0
while [ $i -lt $resource_node_count ]
do
	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/openstack_install.sh /root/openstack_install.sh
#  ./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $BASE_DIR/config/scaleone.properties /root/scaleone.properties
#	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/openstack.iso /root/openstack.iso
#	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $BASE_DIR/install/resource.sh /root/resource.sh 
#  ./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/scaleone_monitor.tar /opt/scaleone_monitor.tar
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "sed -i s%^NovaComputNetInterface.*$%NovaComputNetInterface=${vmnet_eth_name[i]}%g /root/openstack_install.sh"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "sed -i s%^NovaComputManagerInterface.*$%NovaComputManagerInterface=${manager_eth_name[i]}%g /root/openstack_install.sh"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "/root/resource.sh"
#	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "su - nova -c ssh-keygen"
#	./scp_get.sh ${resource_IP[$i]} root ${resource_passwd[$i]} /var/lib/nova/.ssh/id_rsa.pub $INSTALL_PACKAGE_PATH/id_rsa.pub 
#	cat $INSTALL_PACKAGE_PATH/id_rsa.pub >> $INSTALL_PACKAGE_PATH/authorized_keys
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "iptables -I FORWARD -s $dhcp_ip  --sport 67 -j DROP > /dev/null 2>&1 &"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "sed -i s%^server_proxyclient_address.*$%server_proxyclient_address=${resource_IP[$i]}%g /etc/nova/nova.conf"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "/etc/init.d/nova-compute restart"
	echo "${resource_IP[$i]} ${resource_name[$i]}" >> $INSTALL_PACKAGE_PATH/hosts
	i=`expr $i + 1`
done
echo "::1     ip6-localhost ip6-loopback" >> $INSTALL_PACKAGE_PATH/hosts
echo "fe00::0 ip6-localnet" >> $INSTALL_PACKAGE_PATH/hosts
echo "ff00::0 ip6-mcastprefix" >> $INSTALL_PACKAGE_PATH/hosts
echo "ff02::1 ip6-allnodes" >> $INSTALL_PACKAGE_PATH/hosts
echo "ff02::2 ip6-allrouters" >> $INSTALL_PACKAGE_PATH/hosts

./ssh_exec.sh $virtual_ctrl_IP root $virpasswd "mv /etc/hosts /etc/hosts.bak"
./scp_file.sh $virtual_ctrl_IP root $virpasswd $INSTALL_PACKAGE_PATH/hosts /etc/hosts

i=0
while [ $i -lt $resource_node_count ]
do
#	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/authorized_keys /var/lib/nova/.ssh/authorized_keys
#	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "echo \"StrictHostKeyChecking no\" > /var/lib/nova/.ssh/config &"
#	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "chown -R nova:nova /var/lib/nova/.ssh > /dev/null 2>&1 &"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "mv /etc/hosts /etc/hosts.bak"
	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/hosts /etc/hosts
	i=`expr $i + 1`
done	
./rsa.sh