#!/bin/bash

LOGFILE="/tmp/setup.log"
now=$(date +"-%b-%d-%y-%H%M%S")
echo "Start log ${now}" > $LOGFILE

#________________________________
# Mount external volumes

#---
# Allow user to use User-Data volume

vol1_id=$vol1_volid
vol1_dev="/dev/disk/by-id/virtio-$(echo ${vol1_id} | cut -c -20)"
mkdir -p $vol1_mountpoint
mkfs.ext4 ${vol1_dev} && mount ${vol1_dev} $vol1_mountpoint || notify_err "Some problems occurred with block device (Volume 1)"
echo "Successfully device mounted Volume 1"

#---
# Allow user to use Reference-Data volume

#vol2_id=$vol2_volid
#vol2_dev="/dev/disk/by-id/virtio-$(echo ${vol2_id} | cut -c -20)"
#mkdir -p $vol2_mountpoint
#mkfs.ext4 ${vol2_dev} && mount ${vol2_dev} $vol2_mountpoint || notify_err "Some problems occurred with block device (Volume 2)"
#echo "Successfully device mounted Volume 2"


#________________________________
# Copy ansible roles

#---
# Install Ansible

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID > $LOGFILE
    if [ "$ID" = "ubuntu" ]; then
        echo "Distribution: Ubuntu. Using apt" > $LOGFILE
        apt-get -y install software-properties-common &>> $LOGFILE
        apt-add-repository -y ppa:ansible/ansible &>> $LOGFILE
        apt-get -y update &>> $LOGFILE
        #apt-get -y upgrade &>> $LOGFILE
        apt-get -y install ansible git vim python-pycurl wget &>> $LOGFILE
    else
        echo "Distribution: CentOS. Using yum" > $LOGFILE
        yum install -y epel-release &>> $LOGFILE
        yum update -y &>> $LOGFILE
        yum install -y ansible  &>> $LOGFILE #--enablerepo=epel-testing 
        yum install -y git vim  &>> $LOGFILE
    fi
else
    echo "Not running a distribution with /etc/os-release available" > $LOGFILE
fi

# workaround for template module error on Ubuntu 14.04 https://github.com/ansible/ansible/issues/13818
sed -i 's\^#remote_tmp     = ~/.ansible/tmp.*$\remote_tmp     = $HOME/.ansible/tmp\' /etc/ansible/ansible.cfg
sed -i 's\^#local_tmp      = ~/.ansible/tmp.*$\local_tmp      = $HOME/.ansible/tmp\' /etc/ansible/ansible.cfg

# Enable ansible log file
sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' /etc/ansible/ansible.cfg

#---
# Install role
#ansible-galaxy install indigo-dc.galaxycloud,devel &>> $LOGFILE
BRANCH="devel"
git clone https://github.com/indigo-dc/ansible-role-galaxycloud.git /etc/ansible/roles/indigo-dc.galaxycloud &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud && git checkout $BRANCH &>> $LOGFILE

# Run role
wget https://raw.githubusercontent.com/mtangaro/galaxy-cloud-deploy/devel/start-vm/playbook.yml -O /tmp/playbook.yml &>> $LOGFILE

#ansible-playbook /tmp/playbook.yml &>> $LOGFILE 
