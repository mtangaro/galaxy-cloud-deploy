#!/bin/bash

GALAXY=true
BRANCH="master"

TOOLS=true
TOOLS_BRANCH="master"
#TOOLS_BRANCH="handler-include-fix"
#TOOLS_BRANCH="handler-include-static-no"

#______________________________________
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

# workaround for template module error on Ubuntu 14.04 https://github.com/ansible/ansible/issues/13818
sed -i 's\^#remote_tmp     = ~/.ansible/tmp.*$\remote_tmp     = $HOME/.ansible/tmp\' /etc/ansible/ansible.cfg
sed -i 's\^#local_tmp      = ~/.ansible/tmp.*$\local_tmp      = $HOME/.ansible/tmp\' /etc/ansible/ansible.cfg

# Enable ansible log file
sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' /etc/ansible/ansible.cfg

#______________________________________
# Install Ansible roles

# Install ansible-role-galaxycloud
if $GALAXY; then
  git clone https://github.com/mtangaro/ansible-role-galaxycloud-galaxy-install.git /etc/ansible/roles/galaxy-install &>> $LOGFILE
  cd /etc/ansible/roles/galaxy-install && git checkout $BRANCH &>> $LOGFILE
fi

# Install ansible-galaxy-tools
if $TOOLS; then
  git clone https://github.com/indigo-dc/ansible-galaxy-tools.git /etc/ansible/roles/indigo-dc.galaxy-tools &>> $LOGFILE
  cd /etc/ansible/roles/indigo-dc.galaxy-tools && git checkout $TOOLS_BRANCH &>> $LOGFILE
fi
