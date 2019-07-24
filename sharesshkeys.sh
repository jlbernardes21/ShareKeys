#!/bin/bash
# sharekeys.sh - Shell script to share ssh keys between nodes in RAC installation
# Author: Joao Bernardes - https://www.linkedin.com/in/jlbernardes/
# Usage: Needs to be executed in each node. Create a ssh key to all oracle users, and share with all others in all nodes.
#        Important: Define your password to 'orcltoshare' in all users and all nodes and run this script.
#        After the sucessfull execution, the password can be safelly reseted. 

# Basic vars
PASSWORD="orcltoshare"

# check if it is running under root 
if [ "$(id -u)" != "0" ]; then
  echo -e "ERROR: this script needs to be executed by root. " && exit 1
fi

# Get node list from standard input:
if [ "$#" -lt "2" ]; then
  echo "ERROR: You need to pass the list of nodes as parameter in this script (at least two nodes)!"
  echo -e "\nExpected format: \n  $ sharesshkeys.sh node1 node2 nodeN" && exit 1
# That is broken... Fix some day...
#else i=1 && while [ $i -ne $# ]; do
#  currentNode="'$'$i" 
#  echo $currentNode #NODES+=( "$""$i" ) ## Does not work, cause neasted substution is not allowed in bash...
#  #i=$[$i+1]
#  done
#fi
elif [ "$#" -eq "2" ]; then NODES=( $1 $2 )
elif [ "$#" -eq "3" ]; then NODES=( $1 $2 $3 )
elif [ "$#" -eq "4" ]; then NODES=( $1 $2 $3 $4 )
elif [ "$#" -eq "5" ]; then NODES=( $1 $2 $3 $4 $5 )
fi

# Defining USERS array
id -u grid > /dev/null 2>&1 && USERS=( "root" "oracle" "grid" )
if [ $? -ne 0 ]; then
  id -u oracle > /dev/null 2>&1 && USERS=( "root" "oracle" )
  if [ $? -ne 0 ]; then
    echo "ERROR: Oracle user does not exists. Please create then first." && exit 1
  fi
fi

# Identify current distro
egrep -q '^CentOS* release 6' /etc/redhat-release 2> /dev/null && DIST='el6'
egrep -q '^CentOS* release 7' /etc/redhat-release 2> /dev/null && DIST='el7'
egrep -q '^Red Hat Enterprise Linux Server release 6' /etc/redhat-release 2> /dev/null && DIST='el6'
egrep -q '^Red Hat Enterprise Linux Server release 7' /etc/redhat-release 2> /dev/null && DIST='el7'
egrep -q '^Oracle Linux Server release 6' /etc/oracle-release 2> /dev/null && DIST='el6'
egrep -q '^Oracle Linux Server release 7' /etc/oracle-release 2> /dev/null && DIST='el7'

if [ -z "$DIST" ]; then
  echo -e "ERROR: Cannot determine the current distribuition or its not supported by this script" && exit 1
fi

# Cleaning function
cleanup(){
  yum remove -y sshpass 2>&1 > /dev/null
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

which sshpass > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Installing the RPM package SSHPASS. This is a pre-requisite for this script."
  yum -y install sshpass > /dev/null 2>&1
  which sshpass > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    rpm -Uvh $RPMURL > /dev/null 2>&1 
    which sshpass > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo "ERROR: Prereq installation failed (sshpass)" && exit 1
    fi
  fi
fi

# Defining $_SSHPASS
_SSHPASS="sshpass -p $PASSWORD"
_SSH="$_SSHPASS ssh -o StrictHostKeyChecking=no "

# Creating Keys
for us in "${USERS[@]}"; do 
    echo " > Executando a criação de chave para o usuário $us"
    $_SSH $u@$HOSTNAME ssh-keygen -b 2048 -t rsa -q -N ""
  done
done

# Sharing keys
for n in "${NODES[@]}"; do
  for u in "${USERS[@]}"; do 
    $_SSHPASS ssh-copy-id -o StrictHostKeyChecking=no $u@$n
  done
done

echo "Do you want to remove the SSHPASS package? [y/N]" && read REMOVE
if [ -z "$REMOVE" ] || [ "$REMOVE" == "N" ] || [ "$REMOVE" == "n" ]; then
  echo "Skipping sshpass de-install!"
else if [ "$REMOVE" == "y" ]; then
  cleanup
else
  echo "ERROR: Failure while de-installing SSHPASS. Please, run 'yum remove sshpass' manually." && exit 1
fi
fi  

exit 0
