#!/bin/bash
. ./scaleone.properties
if [ "no" = $ifvirtual ]; then  
	virtual_db_IP=$mastnodeIP
	virtual_ctrl_IP=$mastnodeIP
fi
sed -i "/\[mysqld\]/a\character-set-server=utf8" /etc/mysql/my.cnf
service mysql restart
echo -e "\nGRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'intple' WITH GRANT OPTION " >> /home/intple/CreateTable.sql
sed -i "s%CONTROLNODE_DEFAULT%$masthostname%g" /home/intple/CreateTable.sql
if [ "yes" = $share_disk ]; then  
    sed -i "s%DISK_SHARE_MODE%share%g" /home/intple/CreateTable.sql  
else
    sed -i "s%DISK_SHARE_MODE%unshare%g" /home/intple/CreateTable.sql  
fi  
mysql -uroot -pintple < /home/intple/CreateTable.sql
cd /opt;tar -xvf scaleone_monitor.tar
mysql -uroot -pintple < /opt/scaleone_monitor/Createmonitortable.sql
cd /home/intple;tar -zxvf /home/intple/alarm.tar.gz;chmod +x /home/intple/alarm/createtables
/home/intple/alarm/createtables > /dev/null 2>&1 &