#!/bin/bash

yum install -y epel-release
yum install -y ansible

git clone https://github.com/mtangaro/galaxy-cloud-deploy.git /tmp/galaxy-cloud-deploy
cp -r /tmp/galaxy-cloud-deploy/ansible-role-galaxy/* /etc/ansible
