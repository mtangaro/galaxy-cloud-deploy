#!/bin/bash

LOGFILE="/tmp/setup.log"
now=$(date +"-%b-%d-%y-%H%M%S")
echo "Start log ${now}" > $LOGFILE

#________________________________
# Copy and run ansible roles

#---
# Install Ansible

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID > $LOGFILE
    if [ "$ID" = "ubuntu" ]; then
        echo "Distribution: Ubuntu. Using apt" >> $LOGFILE
        apt-get -y install software-properties-common &>> $LOGFILE
        apt-add-repository -y ppa:ansible/ansible &>> $LOGFILE
        apt-get -y update &>> $LOGFILE
        #apt-get -y upgrade &>> $LOGFILE
        apt-get -y install ansible git vim python-pycurl wget &>> $LOGFILE
    else
        echo "Distribution: CentOS. Using yum" >> $LOGFILE
        yum install -y epel-release &>> $LOGFILE
        yum update -y &>> $LOGFILE
        yum install -y ansible  &>> $LOGFILE #--enablerepo=epel-testing 
        yum install -y git vim wget  &>> $LOGFILE
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
# Install roles
ansible-galaxy install indigo-dc.oneclient
ansible-galaxy install indigo-dc.cvmfs-client

# 1. indigo-dc.galaxycloud-os
OS_BRANCH="master"
git clone https://github.com/indigo-dc/ansible-role-galaxycloud-os.git /etc/ansible/roles/indigo-dc.galaxycloud-os &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud-os && git checkout $OS_BRANCH &>> $LOGFILE

# 2. indigo-dc.galaxycloud-fastconfig
BRANCH="master"
git clone https://github.com/indigo-dc/ansible-role-galaxycloud-fastconfig.git /etc/ansible/roles/indigo-dc.galaxycloud-fastconfig &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud-fastconfig && git checkout $BRANCH &>> $LOGFILE

# Run role
wget https://raw.githubusercontent.com/mtangaro/galaxy-cloud-deploy/devel/fastconfig/playbook.yml -O /tmp/playbook.yml &>> $LOGFILE

ansible-playbook /tmp/playbook.yml &>> $LOGFILE
