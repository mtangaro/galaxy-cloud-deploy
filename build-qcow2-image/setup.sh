#!/bin/bash

LOGFILE="/tmp/setup.log"
now=$(date +"-%b-%d-%y-%H%M%S")
echo "Start log ${now}" > $LOGFILE

#________________________________
# Copy ansible roles

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
# Install role
#ansible-galaxy install indigo-dc.galaxycloud,devel &>> $LOGFILE
BRANCH="master"
git clone https://github.com/indigo-dc/ansible-role-galaxycloud.git /etc/ansible/roles/indigo-dc.galaxycloud &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud && git checkout $BRANCH &>> $LOGFILE

# Run role
wget https://raw.githubusercontent.com/mtangaro/galaxy-cloud-deploy/devel/build-qcow2-image/playbook.yml -O /tmp/playbook.yml &>> $LOGFILE

ansible-playbook /tmp/playbook.yml &>> $LOGFILE

#________________________________
# Install cvmfs packages

#________________________________
# Stop postgresql, nginx, proftpd, supervisord, galaxy

# stop postgres
echo 'Stop postgresql' &>> $LOGFILE
if [ "$ID" = "ubuntu" ]; then
  echo "Distribution: Ubuntu." >> $LOGFILE
  systemctl stop postgresql &>> $LOGFILE
else
  echo "Distribution: CentOS." >> $LOGFILE
  systemctl stop postgresql-9.6 &>> $LOGFILE
fi

# stop nginx
echo 'Stop nginx' &>> $LOGFILE
systemctl stop nginx &>> $LOGFILE

# stop proftpd
echo 'Stop proftpd' &>> $LOGFILE
systemctl stop proftpd &>> $LOGFILE

# stop galaxy
echo 'Stop Galaxy' &>> $LOGFILE
galaxyctl stop galaxy &>> $LOGFILE

# shutdown supervisord
echo 'Stop supervisord' &>> $LOGFILE
kill -INT `cat /var/run/supervisord.pid` &>> $LOGFILE

#________________________________
# Remove ansible
echo 'Removing ansible' &>> $LOGFILE
if [ "$ID" = "ubuntu" ]; then
  echo "Distribution: Ubuntu. Using apt." >> $LOGFILE
  apt-get -y autoremove ansible &>> $LOGFILE
else
  echo "Distribution: CentOS. Using yum." >> $LOGFILE
  yum remove -y ansible &>> $LOGFILE
fi

#________________________________
# Remove ansible role
echo 'Removing indigo-dc.galaxycloud' &>> $LOGFILE
rm -rf /etc/ansible/roles/indigo-dc.galaxycloud &>> $LOGFILE

#________________________________
# Remove cloud-init artifact
echo 'Removing cloud-init artifact' &>> $LOGFILE
rm /var/lib/cloud/instance &>> $LOGFILE
rm -rf /var/lib/cloud/instances/* &>> $LOGFILE
rm -rf /var/lib/cloud/data/* &>> $LOGFILE
rm /var/lib/cloud/sem/config_scripts_per_once.once &>> $LOGFILE
rm /var/log/cloud-init.log &>> $LOGFILE
rm /var/log/cloud-init-output.log &>> $LOGFILE
