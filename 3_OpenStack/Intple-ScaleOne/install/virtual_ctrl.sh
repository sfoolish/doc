#!/bin/bash
#set -x
. ./scaleone.properties
if [ "no" = $ifvirtual ]; then  
	virtual_db_IP=$mastnodeIP
	virtual_ctrl_IP=$mastnodeIP
fi
BASE_DIR=$PWD
INSTALL_PACKAGE_PATH=$BASE_DIR
sudo /root/openstack_install.sh control
sudo /root/openstack_install.sh network
sudo /root/openstack_install.sh modify_cfg
sudo apt-get install python-libvirt
sudo apt-get -f install
sudo apt-get install python-libvirt

cd /home/intple;tar -zxvf /home/intple/alarm.tar.gz
cd /home/intple/alarm;chmod +x install;./install

cd /opt;tar -zxvf scaleone.tar.gz
cd /opt/scaleone/webapps;mkdir vmm;cd vmm
/opt/scaleone/jdk1.7.0_21/bin/jar -xvf /opt/scaleone/webapps/vmm.war
sed -i "s%localhost:3306%$virtual_db_IP:3306%g" /opt/scaleone/webapps/vmm/WEB-INF/spring/root-context.xml
sed -i "s%localhost:3306%$virtual_db_IP:3306%g" /opt/scaleone/webapps/manage/WEB-INF/spring/root-context.xml
#sed -i "s%^vmIpRang.*$%vmIpRang=$sharednet%g" /usr/local/etc/alarm.cfg
sed -i "s%^DB_HOSTNAME.*$%DB_HOSTNAME = $virtual_db_IP%g" /usr/local/etc/alarm.cfg
sed -i "s%^host.*$%host=$virtual_ctrl_IP%g" /opt/scaleone/webapps/vmm/WEB-INF/classes/config.properties
sed -i "s%^controlNode.*$%controlNode=$masthostname%g" /opt/scaleone/webapps/vmm/WEB-INF/classes/config.properties

cd /opt;tar -xvf scaleone_monitor.tar
sed -i "s%^DBIP.*$%DBIP=$virtual_db_IP%g" /opt/scaleone_monitor/manager/monitor.cfg 
sed -i "s%^GROUPID.*$%GROUPID=$groupid%g" /opt/scaleone_monitor/manager/monitor.cfg 
cd /opt/scaleone_monitor/manager; ./manager & > /dev/null 2>&1 &

#sed -i /^host_status_host_ip/d /usr/local/etc/alarm.cfg
#sed -i /^host_status_host_name/d /usr/local/etc/alarm.cfg
#sed -i /^host_check_/d /usr/local/etc/alarm.cfg

#i=0
#while [ $i -lt $resource_node_count ]
#do
#	sed -i "/^\[host_status\]/a\host_status_host_name = ${resource_name[${i}]}" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_status\]/a\host_status_host_ip = ${resource_IP[$i]}" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_cvalue = 90" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_wvalue = 80" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_checktype = disk" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_host = ${resource_name[${i}]}" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_cvalue = 90" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_wvalue = 80" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_checktype = mem" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_host = ${resource_name[${i}]}" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_cvalue = 90" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_wvalue = 80" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_checktype = cpu" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_host = ${resource_name[${i}]}" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_cvalue = 90" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_wvalue = 80" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_checktype = net" /usr/local/etc/alarm.cfg
#	sed -i "/^\[host_check\]/a\host_check_host = ${resource_name[${i}]}" /usr/local/etc/alarm.cfg
#	i=`expr $i + 1`
#done	
/usr/local/sbin/alarm.py > /dev/null 2>&1 &
sed -i "/^exit 0/d" /etc/rc.local
echo "/usr/local/sbin/alarm.py > /dev/null 2>&1 &" >> /etc/rc.local
echo "/opt/scaleone/bin/startup.sh > /dev/null 2>&1 &" >> /etc/rc.local
echo "cd /opt/scaleone_monitor/manager/; ./manager > /dev/null 2>&1 &" >> /etc/rc.local
ifconfig eth1 up
ovs-vsctl add-port br-eth1 eth1
echo "ifconfig eth1 up" >> /etc/rc.local

sed -i "s%^share_disk.*$%share_disk=$share_disk%g" /etc/nova/nova.conf
/etc/init.d/nova-api restart > /dev/null 2>&1 &
echo "start do scaleone shutdown.sh"
/opt/scaleone/bin/shutdown.sh > /dev/null 2>&1 &
sleep 5
pkill -9 java
echo "start do scaleone startup.sh"
/opt/scaleone/bin/startup.sh > /dev/null 2>&1 &

