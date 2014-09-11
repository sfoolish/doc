#!/bin/bash
echo "确保正确配置了config目录下scaleone.properties文件中的参数(y/n):"
read test
if [ "n" = $test ]; then  
    exit 1  
fi  
. ../config/scaleone.properties
if [ "no" = $ifvirtual ]; then  
	virtual_db_IP=$mastnodeIP
	virtual_ctrl_IP=$mastnodeIP
fi
BASE_DIR=$PWD/..
INSTALL_PACKAGE_PATH=$BASE_DIR/packages

chmod +x $BASE_DIR/*
#mv /etc/apt/sources.list  /etc/apt/sources.list.original.bak
#cp $BASE_DIR/config/sources.list /etc/apt/sources.list
echo "update system"
sed -i "s%^ControlServAddr=.*$%ControlServAddr=$virtual_ctrl_IP%g" $INSTALL_PACKAGE_PATH/openstack_install.sh
sed -i "s%^DBServer=.*$%DBServer=$virtual_db_IP%g" $INSTALL_PACKAGE_PATH/openstack_install.sh
cp $INSTALL_PACKAGE_PATH/openstack.iso /root
cp $INSTALL_PACKAGE_PATH/openstack_install.sh /root
chmod +x $INSTALL_PACKAGE_PATH/openstack_install.sh
mount -o loop /root/openstack.iso  /media/apt
mv /etc/apt/sources.list  /etc/apt/sources.list.bak
echo "deb file:///media/apt precise main" >> /etc/apt/sources.list
apt-get update
apt-get install -f
sudo apt-get install expect
echo "计算节点打sys_patch,读取计算节点CPU MODEL"
./prepare.sh
#$INSTALL_PACKAGE_PATH/openstack_install.sh sys_patch

sudo apt-get install ethtool
echo "sudo ethtool -s eth0 wol g" >> /etc/rc.local

echo "config br"
cp $BASE_DIR/config/interfaces $BASE_DIR/config/interfaces_tmp
sed -i "s#mastinterface#$mastinterface#g" $BASE_DIR/config/interfaces_tmp
sed -i "s#mastnodeIP#$mastnodeIP#g" $BASE_DIR/config/interfaces_tmp
sed -i "s#mastnetmask#$mastnetmask#g" $BASE_DIR/config/interfaces_tmp
sed -i "s#mastnetwork#$mastnetwork#g" $BASE_DIR/config/interfaces_tmp
sed -i "s#mastbroadcast#$mastbroadcast#g" $BASE_DIR/config/interfaces_tmp
sed -i "s#mastgateway#$mastgateway#g" $BASE_DIR/config/interfaces_tmp
sed -i "s#mastdnsnameservers#$mastdnsnameservers#g" $BASE_DIR/config/interfaces_tmp
mv /etc/network/interfaces /etc/network/interfaces_bak
mv $BASE_DIR/config/interfaces_tmp /etc/network/interfaces
#echo "ifconfig eth1 up" >> /etc/rc.local
echo "主机配置完毕，请检查/etc/network/interfaces文件内容正确后执行/etc/init.d/networking restart重启网络，然后执行setup2.sh"

