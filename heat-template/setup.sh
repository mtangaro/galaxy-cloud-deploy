#!/bin/bash

OS_BRANCH="master"

BRANCH="devel"

TOOLS_BRANCH="master"
#TOOLS_BRANCH="handler-include-fix"
#TOOLS_BRANCH="handler-include-static-no"

TOOLDEPS_BRANCH="master"

REFDATA_BRANCH="master"

#______________________________________
# Mount external volumes

###voldata_id=$vol1_id
vol1_dev="/dev/disk/by-id/virtio-$(echo ${vol1_id} | cut -c -20)"
mkdir -p $vol1_mountpoint
mkfs.ext4 ${vol1_dev} && mount ${vol1_dev} $vol1_mountpoint || notify_err "Some problems occurred with block device (volume 1)"
echo "Successfully device mounted (volume 1)"

#voldata_id=$vol2_id
#ref_vol2_dev="/dev/disk/by-id/virtio-$(echo ${vol2_id} | cut -c -20)"
#mkdir -p $vol2_mountpoint
#mkfs.ext4 ${vol2_dev} && mount ${vol2_dev} $vol2_mountpoint || notify_err "Some problems occurred with block device (reference data)"
#echo "Successfully device mounted (volume 2)"


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
        yum update -y &>> $LOGFILE
        yum install -y ansible  &>> $LOGFILE #--enablerepo=epel-testing
        yum install -y git vim &>> $LOGFILE
        # get orchetrator ansible version
        #yum remove -y ansible &>> $LOGFILE
        #wget http://cbs.centos.org/kojifiles/packages/ansible/2.2.1.0/2.el7/noarch/ansible-2.2.1.0-2.el7.noarch.rpm -P /tmp
        #yum --nogpgcheck localinstall -y /tmp/ansible-2.2.1.0-2.el7.noarch.rpm 
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

ansible-galaxy install indigo-dc.oneclient
ansible-galaxy install indigo-dc.cvmfs-client

# 1. indigo-dc.galaxycloud-os
git clone https://github.com/indigo-dc/ansible-role-galaxycloud-os.git /etc/ansible/roles/indigo-dc.galaxycloud-os &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud-os && git checkout $OS_BRANCH &>> $LOGFILE

# 2. indigo-dc.galaxycloud
git clone https://github.com/indigo-dc/ansible-role-galaxycloud.git /etc/ansible/roles/indigo-dc.galaxycloud &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud && git checkout $BRANCH &>> $LOGFILE

# 3. indigo-dc.galaxy-tools
git clone https://github.com/indigo-dc/ansible-galaxy-tools.git /etc/ansible/roles/indigo-dc.galaxy-tools &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxy-tools && git checkout $TOOLS_BRANCH &>> $LOGFILE

git clone https://github.com/mtangaro/ansible-role-galaxycloud-tooldeps.git /etc/ansible/roles/indigo-dc.galaxycloud-tooldeps &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud-tooldeps && git checkout $TOOLDEPS_BRANCH &>> $LOGFILE

# 4. indigo-dc.galaxycloud-refdata
git clone https://github.com/indigo-dc/ansible-role-galaxycloud-refdata.git /etc/ansible/roles/indigo-dc.galaxycloud-refdata &>> $LOGFILE
cd /etc/ansible/roles/indigo-dc.galaxycloud-refdata && git checkout $REFDATA_BRANCH &>> $LOGFILE
