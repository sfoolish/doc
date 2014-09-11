#!/bin/bash
#set -x
. ../config/scaleone.properties

BASE_DIR=$PWD/..
INSTALL_PACKAGE_PATH=$BASE_DIR/packages

i=0
while [ ${i} -lt ${resource_node_count} ]
do
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "groupadd -r kvm -g 400"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "groupadd -r libvirtd -g 401"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "groupadd -r nova -g 413"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "groupadd -r cinder -g 415"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "groupadd -r quantum -g 416"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "useradd -r libvirt-qemu -u 402 -g 400 -d /var/lib/libvirt -s /bin/false"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "useradd -r libvirt-dnsmasq -u 403 -g 401 -d /var/lib/libvirt/dnsmasq -s /bin/false"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "useradd -r nova -u 404 -g 413 -G 401 -d /var/lib/nova -s /bin/bash"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "useradd -r cinder -u 406 -g 415 -d /var/lib/cinder -s /bin/false"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "useradd -r quantum -u 407 -g 416 -d /var/lib/quantum -s /bin/false"
	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/openstack_install.sh /root/openstack_install.sh
  ./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $BASE_DIR/config/scaleone.properties /root/scaleone.properties
	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/openstack.iso /root/openstack.iso
	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $BASE_DIR/install/resource.sh /root/resource.sh 
	./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $BASE_DIR/install/cpu_model.sh /root/cpu_model.sh 
  ./scp_file.sh ${resource_IP[$i]} root ${resource_passwd[$i]} $INSTALL_PACKAGE_PATH/scaleone_monitor.tar /opt/scaleone_monitor.tar
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "sed -i s%^NovaComputNetInterface.*$%NovaComputNetInterface=${vmnet_eth_name[i]}%g /root/openstack_install.sh"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "sed -i s%^NovaComputManagerInterface.*$%NovaComputManagerInterface=${vmnet_eth_name[i]}%g /root/openstack_install.sh"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "/root/openstack_install.sh sys_patch"
	./ssh_exec.sh ${resource_IP[$i]} root ${resource_passwd[$i]} "/root/cpu_model.sh"
	./scp_get.sh ${resource_IP[$i]} root ${resource_passwd[$i]} /root/cpu_model $INSTALL_PACKAGE_PATH/CPU_MODEL_${resource_IP[$i]}
	i=`expr $i + 1`
done

test=`cat $INSTALL_PACKAGE_PATH/CPU_MODEL_*`
Nehalem=0
Westmere=0
SandyBridge=0
Haswell=0
Opteron_G1=0
Opteron_G2=0
Opteron_G3=0
Opteron_G4=0
Opteron_G5=0

for i in $test;
do
case $i in
  Nehalem)
     Nehalem=`expr $Nehalem + 1`
     ;;
  Westmere)
     Westmere=`expr $Westmere + 1`
     ;;
  SandyBridge)
     SandyBridge=`expr $SandyBridge + 1`
     ;;
  Haswell)
     SandyBridge=`expr $SandyBridge + 1`
     ;;
  Opteron_G1)
     Opteron_G1=`expr $Opteron_G1 + 1`
     ;;
  Opteron_G2)
     Opteron_G2=`expr $Opteron_G2 + 1`
     ;;
  Opteron_G3)
     Opteron_G3=`expr $Opteron_G3 + 1`
     ;;
  Opteron_G4)
     Opteron_G4=`expr $Opteron_G4 + 1`
     ;;
  Opteron_G5)
     Opteron_G5=`expr $Opteron_G5 + 1`
     ;;
esac 
done

if [ 0 -lt $Nehalem ]; then
	cpu_model="Nehalem"
elif [ 0 -lt $Westmere ]; then
	cpu_model="Westmere"
elif [ 0 -lt $SandyBridge ]; then
	cpu_model="SandyBridge"
elif [ 0 -lt $Haswell ]; then
	cpu_model="Haswell"
elif [ 0 -lt $Opteron_G1 ]; then
	cpu_model="Opteron_G1"
elif [ 0 -lt $Opteron_G2 ]; then
	cpu_model="Opteron_G2"
elif [ 0 -lt $Opteron_G3 ]; then
	cpu_model="Opteron_G3"
elif [ 0 -lt $Opteron_G4 ]; then
	cpu_model="Opteron_G4"
elif [ 0 -lt $Opteron_G5 ]; then
	cpu_model="Opteron_G5"
else
	echo "ERROR for get cpu_model"
fi
sed -i "s%^LibVirtCpuModel=.*$%LibVirtCpuModel=$cpu_model%g" $INSTALL_PACKAGE_PATH/openstack_install.sh
