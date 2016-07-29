#!/bin/bash

#######################################
# Mount external volumes
#######################################

#Allow user to use User-Data volume
#voldata_id=$userdata_volid
#voldata_dev="/dev/disk/by-id/virtio-$(echo ${voldata_id} | cut -c -20)"
#mkdir -p $userdata_mountpoint
#mkfs.ext4 ${voldata_dev} && mount ${voldata_dev} $userdata_mountpoint || notify_err "Some problems occurred with block device (working dir)"
#echo "Successfully device mounted (working dir)"
#mkdir -p $userdata_mountpoint/galaxy
#chown -R galaxy:galaxy $userdata_mountpoint/galaxy

#Allow user to use Reference-Data volume
#ref_voldata_id=$refdata_volid
#ref_voldata_dev="/dev/disk/by-id/virtio-$(echo ${ref_voldata_id} | cut -c -20)"
#mkdir -p $refdata_mountpoint
#mkfs.ext4 ${ref_voldata_dev} && mount ${ref_voldata_dev} $refdata_mountpoint || notify_err "Some problems occurred with block device (reference data)"
#echo "Successfully device mounted (reference data)"
#mkdir -p $refdata_mountpoint/galaxy
#chown -R galaxy:galaxy $refdata_mountpoint/galaxy


#######################################
# Copy ansible roles
#
# This section install Ansible and copy to /etc/ansible/roles
# the ansible-role-galaxycloud and related playbooks
#######################################

# Install Ansible
yum install -y epel-release
yum update -y
yum install -y ansible git

# Install ansible-role-galaxycloud
git clone https://github.com/indigo-dc/ansible-role-galaxycloud.git /tmp/galaxycloud
cd /tmp/galaxycloud && git checkout devel
cp -r /tmp/galaxycloud /etc/ansible/roles/

# Enable ansible log file
sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' /etc/ansible/ansible.cfg

