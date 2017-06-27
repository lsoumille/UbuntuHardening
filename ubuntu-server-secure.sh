#!/bin/sh
#
# Ubuntu Server 16.04 Hardening - July 2017
# 
#
echo
echo "* Ubuntu Server 16.04 Hardening - July 2017"
echo 
# Local Variables

UserName=$(whoami)
LogDay=$(date '+%Y-%m-%d')
LogTime=$(date '+%Y-%m-%d %H:%M:%S')
LogFile=/var/log/hardening_$LogDay.log

# Install & Configure UFW
echo "$LogTime hardening: [$UserName] 1. Install and configure Firewall - ufw" >> $LogFile
echo "# 1. Install and configure :Firewall - ufw "
echo "# Check if ufw Firewall is installed..."
echo "$LogTime hardening: [$UserName] Check if ufw Firewall is installed..." >> $LogFile
if [ -f /usr/sbin/ufw ]
  then
    echo "# ufw Firewall is already installed"
    echo "$LogTime hardening: [$UserName] ufw Firewall is already installed" >> $LogFile
fi
if [ ! -f /usr/sbin/ufw ]
  then
    echo "# ufw Firewall NOT installed, installing..."
    echo "$LogTime hardening: [$UserName] ufw Firewall NOT installed, installing..." >> $LogFile
    sudo apt-get install -y ufw                 
fi
echo "$LogTime hardening: [$UserName] Disable UFW to make changes" >> $LogFile
sudo ufw disable
echo "# Configure UFW default policy"
echo "$LogTime hardening: [$UserName] Configure UFW default policy" >> $LogFile
sudo ufw default deny incoming > /dev/null
echo "# Configure UFW HTTP & SSH"
echo "$LogTime hardening: [$UserName] Configure UFW HTTP & SSH" >> $LogFile
sudo ufw allow ssh > /dev/null
sudo ufw allow http > /dev/null
echo "# Configure UFW for LMC"
echo "$LogTime hardening: [$UserName] Configure UFW for LMC" >> $LogFile
#ELASTICSEARCH
sudo ufw allow 9200 > /dev/null
#KIBANA
sudo ufw allow 5601 > /dev/null
#STORM UI
sudo ufw allow 8080 > /dev/null
#GRAFANA
sudo ufw allow 3000 > /dev/null
#ADMIN
sudo ufw allow 5000 > /dev/null
echo "$LogTime hardening: [$UserName] enable UFW to validate changes" >> $LogFile
sudo ufw enable
echo ; sleep 0.1

# Secure Shared Memory 
echo "$LogTime hardening: [$UserName] 2. Secure Shared Memory" >> $LogFile
echo "# 2. Secure Shared Memory"
echo "# Check if shared memory is secured"
echo "$LogTime hardening: [$UserName] Check if shared memory is secured" >> $LogFile           
fstab=$(grep -c "tmpfs" /etc/fstab)
if [ ! "$fstab" -eq "0" ] 
  then
    echo "# fstab already contains a tmpfs partition. Nothing to be done."
    echo "$LogTime hardening: [$UserName] fstab already contains a tmpfs partition. Nothing to be done." >> $LogFile
fi
if [ "$fstab" -eq "0" ]
  then
    echo "# fstab being updated to secure shared memory"
    echo "$LogTime hardening: [$UserName] fstab being updated to secure shared memory" >> $LogFile
    sudo echo "tmpfs     /run/shm     tmpfs     defaults,noexec,nosuid     0     0" >> /etc/fstab
    echo "# Shared memory secured. Remount partition"
    echo "$LogTime hardening: [$UserName] Shared memory secured. Remount partition" >> $LogFile
    sudo mount -o remount /run/shm
fi
echo ; sleep 0.1

# SSH Hardening - disable root login
echo "$LogTime hardening: [$UserName] 3. SSH Hardening" >> $LogFile
echo "# 3. SSH Hardening"
rm /tmp/sshInstalled
dpkg -l openssh-server > /tmp/sshInstalled
sshInstalled=$(grep -c "no packages found" /tmp/sshInstalled)
echo $sshInstalled
if [ ! "$sshInstalled" -eq "0" ]
  then
  echo "# Update SSH settings"
  echo "$LogTime hardening: [$UserName] Check if PermitRootLogin entry exists comment out old entrie" >> $LogFile 
  sshconfigPermitRoot=$(grep -c "PermitRootLogin" /etc/ssh/sshd_config)
  if [ ! "$sshconfigPermitRoot" -eq "0" ] 
    then
      # if entry exists use sed to search and replace - write to tmp file - move to original 
      sudo sed 's/PermitRootLogin/#PermitRootLogin/g' /etc/ssh/sshd_config > /tmp/.sshd_config
      sudo mv /etc/ssh/sshd_config /etc/ssh/ssh_config.backup
      sudo mv /tmp/.sshd_config /etc/ssh/sshd_config
  fi
  echo "# Write new SSH Configuration settings"
  echo "$LogTime hardening: [$UserName] Write new SSH Configuration settings" >> $LogFile
  sudo echo "PermitRootLogin no" >> /etc/ssh/sshd_config
  echo "# SSH settings update complete"
  echo "$LogTime hardening: [$UserName] SSH settings update complete" >> $LogFile
  echo "# Restart SSH service"
  echo "$LogTime hardening: [$UserName] SSH server restarted" >> $LogFile
  sudo service sshd restart
fi
if [ "$sshInstalled" -eq "0" ]
  then
  echo "# Update SSH settings"
  echo "$LogTime hardening: [$UserName] Check if PermitRootLogin entry exists comment out old entrie" >> $LogFile 
fi

echo ; sleep 0.1


