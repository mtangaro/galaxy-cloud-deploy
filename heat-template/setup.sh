#!/bin/bash

# copy ansible roles

yum install -y epel-release
yum install -y ansible

git clone https://github.com/mtangaro/ansible-role-galaxycloud.git /tmp/galaxycloud
cp -r /tmp/galaxycloud /etc/ansible/roles/

#enable ansible log file
sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' /etc/ansible/ansible.cfg
