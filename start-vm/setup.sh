#!/bin/bash

LOGFILE="/tmp/setup.log"
now=$(date +"-%b-%d-%y-%H%M%S")
echo "Start log ${now}" > $LOGFILE

#________________________________
# Mount external volumes

#---
# Allow user to use User-Data volume

vol1_id=$vol1_volid
vol1_dev="/dev/disk/by-id/virtio-$(echo ${vol1_id} | cut -c -20)"
mkdir -p $vol1_mountpoint
mkfs.ext4 ${vol1_dev} && mount ${vol1_dev} $vol1_mountpoint || notify_err "Some problems occurred with block device (Volume 1)"
echo "Successfully device mounted Volume 1"

#---
# Allow user to use Reference-Data volume

#vol2_id=$vol2_volid
#vol2_dev="/dev/disk/by-id/virtio-$(echo ${vol2_id} | cut -c -20)"
#mkdir -p $vol2_mountpoint
#mkfs.ext4 ${vol2_dev} && mount ${vol2_dev} $vol2_mountpoint || notify_err "Some problems occurred with block device (Volume 2)"
#echo "Successfully device mounted Volume 2"

#________________________________
# Install Ansible

if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    echo $ID > $LOGFILE
    if [ "$ID" = "ubuntu" ]; then
        echo "Distribution: Ubuntu. Using apt" > $LOGFILE
        #Remove old ansible as workaround for https://github.com/ansible/ansible-modules-core/issues/5144
        dpkg -r ansible
        apt-get autoremove -y
        #install ansible 2.2.1 (version used in INDIGO)
        apt-get -y update &>> $LOGFILE
        apt-get install -y python-pip python-dev libffi-dev libssl-dev python-virtualenv &>> $LOGFILE #https://github.com/geerlingguy/JJG-Ansible-Windows/issues/28
        apt-get -y install git vim python-pycurl wget&>> $LOGFILE
    else
        echo "Distribution: CentOS. Using yum" > $LOGFILE
        yum install -y epel-release &>> $LOGFILE
#        yum update -y &>> $LOGFILE
        yum groupinstall -y "Development Tools" &>> $LOGFILE
        yum install -y python-pip python-devel libffi-devel openssl-devel python-virtualenv &>> $LOGFILE
        yum install -y git vim wget  &>> $LOGFILE
    fi
else
    echo "Not running a distribution with /etc/os-release available" > $LOGFILE
fi

# Install ansible in a specific virtual environment
ansible_venv=/tmp/myansible
virtualenv --system-site-packages $ansible_venv &>> $LOGFILE
. $ansible_venv/bin/activate &>> $LOGFILE
pip install pip --upgrade &>> $LOGFILE
pip install ansible==2.2.1 &>> $LOGFILE

# workaround for template module error on Ubuntu 14.04 https://github.com/ansible/ansible/issues/13818
#sed -i 's\^#remote_tmp     = ~/.ansible/tmp.*$\remote_tmp     = $HOME/.ansible/tmp\' /etc/ansible/ansible.cfg
#sed -i 's\^#local_tmp      = ~/.ansible/tmp.*$\local_tmp      = $HOME/.ansible/tmp\' /etc/ansible/ansible.cfg

# Enable ansible log file
#sed -i 's\^#log_path = /var/log/ansible.log.*$\log_path = /var/log/ansible.log\' /etc/ansible/ansible.cfg

# workaround for https://github.com/ansible/ansible/issues/20332
#sed -i 's:#remote_tmp:remote_tmp:' /etc/ansible/ansible.cfg

#________________________________
# Install roles

role_dir=/tmp/roles
mkdir -p $role_dir

OS_BRANCH="devel"
BRANCH="devel"
TOOLS_BRANCH="devel"
TOOLDEPS_BRANCH="galaxyctl"
REFDATA_BRANCH="devel"

# Dependencies
ansible-galaxy install --roles-path $role_dir indigo-dc.galaxycloud-indigorepo &>> $LOGFILE
ansible-galaxy install --roles-path $role_dir indigo-dc.oneclient &>>$LOGFILE
ansible-galaxy install --roles-path $role_dir indigo-dc.cvmfs-client,devel &>> $LOGFILE

# 1. indigo-dc.galaxycloud-os
git clone https://github.com/indigo-dc/ansible-role-galaxycloud-os.git $role_dir/indigo-dc.galaxycloud-os &>> $LOGFILE
cd $role_dir/indigo-dc.galaxycloud-os && git checkout $OS_BRANCH &>> $LOGFILE

# 2. indigo-dc.galaxycloud
git clone https://github.com/indigo-dc/ansible-role-galaxycloud.git $role_dir/indigo-dc.galaxycloud &>> $LOGFILE
cd $role_dir/indigo-dc.galaxycloud && git checkout $BRANCH &>> $LOGFILE

#### 3. indigo-dc.galaxy-tools
#git clone https://github.com/indigo-dc/ansible-galaxy-tools.git $role_dir/indigo-dc.galaxy-tools &>> $LOGFILE
#cd $role_dir/indigo-dc.galaxy-tools && git checkout $TOOLS_BRANCH &>> $LOGFILE

# 3. indigo-dc.galaxycloud-tools
git clone https://github.com/indigo-dc/ansible-role-galaxycloud-tools.git $role_dir/indigo-dc.galaxycloud-tools &>> $LOGFILE
cd $role_dir/indigo-dc.galaxycloud-tools && git checkout $TOOLS_BRANCH &>> $LOGFILE

git clone https://github.com/indigo-dc/ansible-role-galaxycloud-tooldeps.git $role_dir/indigo-dc.galaxycloud-tooldeps &>> $LOGFILE
cd $role_dir/indigo-dc.galaxycloud-tooldeps && git checkout $TOOLDEPS_BRANCH &>> $LOGFILE

# 4. indigo-dc.galaxycloud-refdata
git clone https://github.com/indigo-dc/ansible-role-galaxycloud-refdata.git $role_dir/indigo-dc.galaxycloud-refdata &>> $LOGFILE
cd $role_dir/indigo-dc.galaxycloud-refdata && git checkout $REFDATA_BRANCH &>> $LOGFILE

#________________________________
# Run play

PLAYBOOK="playbook_galaxy.yml"
wget https://raw.githubusercontent.com/mtangaro/galaxy-cloud-deploy/devel/start-vm/$PLAYBOOK -O /tmp/playbook.yml &>> $LOGFILE
ansible-playbook /tmp/playbook.yml &>> $LOGFILE 
