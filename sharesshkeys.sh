#!/bin/bash
# sharekeys.sh - Shell script to share ssh keys between nodes in RAC installation
# Author: Joao Bernardes - https://www.linkedin.com/in/jlbernardes/
#

# Install dependencies (sshpass):
>> Verify distro
>> install rpm

# Basic vars
USERS=( "oracle" "grid" "root") 
# Get node list from standard input:
if [ -z "$1" ]; then
  echo "\$You need to pass the list of nodes as parameter in this script!"
else
  NODES="$1"
fi

# Converting string tempnodelist (basic string) to array
bkpNODES="$NODES"
bkpIFS="$IFS"
IFS=',()][' read -r -a NODES <<<"([$bkpNODES])"
IFS="$bkpIFS"

echo ${NODES[@]}

for i in ${NODES[@]}; do
  ssh $i ssh-keygen (parametros pra gerar autmoaticamente RSA e DSA) 
  for i in ${NODES[@]}; do
    for j in ${USERS[@]}; do
      sshpass <params apropriados> ssh-copy-id $j@$i
      ssh $j@$i echo
    done
  done  
done
