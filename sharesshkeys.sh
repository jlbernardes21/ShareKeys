#!/bin/bash
# sharekeys.sh - Shell script to share ssh keys between nodes in RAC installation
# Author: Joao Bernardes - https://www.linkedin.com/in/jlbernardes/
#

# Basic vars
USERS=( "oracle" "grid" "root") 
# Get node list from standard input:
if [ -z "$1" ]; then
  echo "\$You need to pass the list of nodes as parameter in this script!"
else
  NODES="$1"
fi

# Check if the node list is
if [[ $NODES != *","* ]]; then
  echo -e "\nERROR: the node list needs to be passed in an incorrect format."
  echo -e "\nExpected format: \n  $ sharesshkeys.sh node1,node2,nodeN" && exit 1
fi

# check if it is running under root 
if [ "$(id -u)" != "0" ]; then
  echo -e "\nError: this script needs to be executed by root. " && exit 1
fi

# Identify current distro
egrep -q '^CentOS* release 6' /etc/redhat-release 2> /dev/null && DIST='el6'
egrep -q '^CentOS* release 7' /etc/redhat-release 2> /dev/null && DIST='el7'
egrep -q '^Red Hat Enterprise Linux Server release 6' /etc/redhat-release 2> /dev/null && DIST='el6'
egrep -q '^Red Hat Enterprise Linux Server release 7' /etc/redhat-release 2> /dev/null && DIST='el7'
egrep -q '^Oracle Linux Server release 6' /etc/oracle-release 2> /dev/null && DIST='el6'
egrep -q '^Oracle Linux Server release 7' /etc/oracle-release 2> /dev/null && DIST='el7'

if [ -z "$DIST" ]; then
  echo -e "\nERROR: Cannot determine the current distribuition or its not supported by this script" && exit 1
fi

# Cleaning function
cleaning(){
  yum remove sshpass
}

# Install dependencies (sshpass)
case $DIST in
  "el6") 
    # Mirror: Epel
    # More info: https://centos.pkgs.org/6/epel-x86_64/sshpass-1.06-1.el6.x86_64.rpm.html
    RPMURL="http://download-ib01.fedoraproject.org/pub/epel/6/x86_64/Packages/s/sshpass-1.06-1.el6.x86_64.rpm"
    ;;
  
  "el7")
    # Mirror: Rpmforge
    # More info: https://centos.pkgs.org/7/repoforge-x86_64/sshpass-1.05-1.el7.rf.x86_64.rpm.html
    RPMURL="http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el7/en/x86_64/rpmforge/RPMS/sshpass-1.05-1.el7.rf.x86_64.rpm"
    ;;
esac

which sshpass 2>&1 > /dev/null
if [ $? -eq 0 ]; then
  _SSHPASS=`which sshpass`
else
  yum -y install sshpass 2>&1 > /dev/null
  if [ $? -eq 0 ]; then
    _SSHPASS=`which sshpass`
  else
    rpm -Uvh $RPMURL 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
      _SSHPASS=`which sshpass`
    else
      echo "\nERROR: Pre-req installation failed (sshpass)" && exit 1
    fi
  fi
fi

# Converting string tempnodelist (basic string) to array
bkpNODES="$NODES"
bkpIFS="$IFS"
IFS=',()][' read -r -a NODES <<<"([$bkpNODES])"
IFS="$bkpIFS"

echo ${NODES[@]}

#for i in ${NODES[@]}; do
#  ssh $i ssh-keygen (parametros pra gerar autmoaticamente RSA e DSA) 
#  for i in ${NODES[@]}; do
#    for j in ${USERS[@]}; do
#      sshpass <params apropriados> ssh-copy-id $j@$i
#      ssh $j@$i echo
#    done
#  done  
#done

exit 0
