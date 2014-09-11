#!/bin/bash
BASE_DIR=/root
INSTALL_PACKAGE_PATH=$BASE_DIR

. ./scaleone.properties
/sbin/iptables -A FORWARD -s ${dhcp_ip}/32 -p udp -m udp --sport 67 -j DROP
/sbin/iptables -A FORWARD -j ACCEPT

echo "* * * * * root /sbin/iptables -R FORWARD 1 -p udp -s $dhcp_ip --sport 67 -j DROP" >> /etc/crontab
echo "* * * * * root /sbin/iptables -R FORWARD 2 -j ACCEPT" >> /etc/crontab

sudo apt-get install ethtool
chmod +x $INSTALL_PACKAGE_PATH/openstack_install.sh
#$INSTALL_PACKAGE_PATH/openstack_install.sh sys_patch
$INSTALL_PACKAGE_PATH/openstack_install.sh compute
sed -i '/nova/{ s#/bin/false#/bin/bash#; }' /etc/passwd
echo "listen_tcp=1" >> /etc/libvirt/libvirtd.conf
echo "listen_tls=0" >> /etc/libvirt/libvirtd.conf
echo "listen_addr=\"0.0.0.0\"" >> /etc/libvirt/libvirtd.conf
echo "auth_tcp = \"none\"" >> /etc/libvirt/libvirtd.conf
sed -i "s%^libvirtd_opts.*$%libvirtd_opts=\"-l -d\"%g" /etc/default/libvirt-bin
ifconfig eth1 up
ovs-vsctl add-port br-eth1 eth1
echo "ifconfig eth1 up" >> /etc/rc.local
echo "cd /opt/scaleone_monitor/host/; ./host &" >> /etc/rc.local
/etc/init.d/nova-compute restart
#service ganglia-monitor start
cd /opt;tar -xvf scaleone_monitor.tar
sed -i "s%^GROUPID.*$%GROUPID=$groupid%g" /opt/scaleone_monitor/host/monitor.cfg 
cd /opt/scaleone_monitor/host;./host > /dev/null 2>&1 &