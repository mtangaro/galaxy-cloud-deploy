#!/bin/bash

# copy ansible roles

yum install -y epel-release
yum install -y ansible

git clone https://github.com/mtangaro/ansible-role-galaxycloud.git /tmp/galaxycloud
cp -r /tmp/galaxycloud /etc/ansible/roles/
