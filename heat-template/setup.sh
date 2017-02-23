#!/bin/bash

#######################################
# Mount external volumes
#######################################

#---
# Allow user to use User-Data volume

#voldata_id=$userdata_volid
#voldata_dev="/dev/disk/by-id/virtio-$(echo ${voldata_id} | cut -c -20)"
#mkdir -p $userdata_mountpoint
#mkfs.ext4 ${voldata_dev} && mount ${voldata_dev} $userdata_mountpoint || notify_err "Some problems occurred with block device (working dir)"
#echo "Successfully device mounted (working dir)"

#---
# Allow user to use Reference-Data volume

#ref_voldata_id=$refdata_volid
#ref_voldata_dev="/dev/disk/by-id/virtio-$(echo ${ref_voldata_id} | cut -c -20)"
#mkdir -p $refdata_mountpoint
#mkfs.ext4 ${ref_voldata_dev} && mount ${ref_voldata_dev} $refdata_mountpoint || notify_err "Some problems occurred with block device (reference data)"
#echo "Successfully device mounted (reference data)"

#######################################
# Copy ansible roles
#
# This section install Ansible and copy to /etc/ansible/roles
# the ansible-role-galaxycloud and related playbooks
#######################################


# Install Ansible

LOGFILE="/tmp/setup.log"

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID > $LOGFILE
    if [ "$ID" = "ubuntu" ]; then
        echo "Distribution: Ubuntu. Using apt" > $LOGFILE
        apt-get -y install software-properties-common &>> $LOGFILE
        apt-add-repository -y ppa:ansible/ansible &>> $LOGFILE
        apt-get -y update &>> $LOGFILE
        apt-get -y install ansible git vim &>> $LOGFILE
    else
        echo "Distribution: CentOS. Using yum" > $LOGFILE
        yum install -y epel-release &>> $LOGFILE
        #yum update -y &>> $LOGFILE
        yum install -y ansible  &>> $LOGFILE #--enablerepo=epel-testing 
        yum install -y git vim  &>> $LOGFILE
    fi
else
    echo "Not running a distribution with /etc/os-release available" > $LOGFILE
fi

# Enable ansible log file
sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' /etc/ansible/ansible.cfg

#
# Install Ansible roles
#

OS=true
GALAXY=true
TOOLS=true
REFDATA=true

###
# 1. Install ansible-role-galaxycloud-os
if $OS; then
  git clone https://github.com/mtangaro/ansible-role-galaxycloud-os.git /tmp/galaxycloud-os &>> $LOGFILE
  cd /tmp/galaxycloud-os && git checkout master &>> $LOGFILE
  cp -r /tmp/galaxycloud-os /etc/ansible/roles/
fi

###
# 2. Install ansible-role-galaxycloud
BRANCH="master"
if $GALAXY; then
  git clone https://github.com/indigo-dc/ansible-role-galaxycloud.git /tmp/galaxycloud &>> $LOGFILE
  cd /tmp/galaxycloud && git checkout $BRANCH &>> $LOGFILE
  cp -r /tmp/galaxycloud /etc/ansible/roles/
fi

###
# 3. Install ansible-galaxy-tools
if $TOOLS; then
  git clone https://github.com/indigo-dc/ansible-galaxy-tools.git /tmp/galaxy-tools &>> $LOGFILE
  cd /tmp/galaxy-tools && git checkout master &>> $LOGFILE
  cp -r /tmp/galaxy-tools /etc/ansible/roles/
fi

###
# 4. Install ansible-role-galaxycloud-refdata
if $REFDATA; then
  git clone https://github.com/mtangaro/ansible-role-galaxycloud-refdata.git /tmp/galaxycloud-refdata &>> $LOGFILE
  cd /tmp/galaxycloud-refdata && git checkout master &>> $LOGFILE
  cp -r /tmp/galaxycloud-refdata /etc/ansible/roles/
fi
