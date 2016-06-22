#!/bin/bash

#######################################
# Copy ansible roles
#
# This script install Ansible and copy to /etc/ansible/roles
# the ansible-role-galaxycloud and related playbooks
#######################################

# Install Ansible
yum install -y epel-release
yum update -y
yum install -y ansible git

# Install ansible-role-galaxycloud
git clone https://github.com/mtangaro/ansible-role-galaxycloud.git /tmp/galaxycloud
cd /tmp/galaxycloud && git checkout devel
cp -r /tmp/galaxycloud /etc/ansible/roles/

# Install galaxy-tool playbook and  galaxyproject/ansible-galaxy-tools
git clone --recursive https://github.com/mtangaro/galaxycloud-tools-playbook.git /tmp/galaxycloud-tools
cp -r /tmp/galaxycloud-tools/* /etc/ansible/

# Enable ansible log file
sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' /etc/ansible/ansible.cfg

