#!/bin/bash
echo "ȷ����ȷ������configĿ¼��scaleone.properties�ļ��еĲ���(y/n):"
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
echo "����ڵ��sys_patch,��ȡ����ڵ�CPU MODEL"
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
echo "����������ϣ�����/etc/network/interfaces�ļ�������ȷ��ִ��/etc/init.d/networking restart�������磬Ȼ��ִ��setup2.sh"

