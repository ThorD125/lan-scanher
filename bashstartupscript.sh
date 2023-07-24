#!/usr/bin/bash

NC='\033[0m'
Red='\033[0;31m'
Light_Red='\033[1;31m'
Green='\033[0;32m'
Brown='\033[0;33m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
Purple='\033[0;35m'
Light_Purple='\033[1;35m'
Cyan='\033[0;36m'
White='\033[1;37m'

alias sshraspi0="ssh ther@192.168.1.110"


netip=$(cat /etc/resolv.conf | grep nameserver | cut -d " " -f 2)
echo -e ${Yellow}domain name server or dns server: $NC
echo $netip

echo
defaultgateway=$(ip r | grep default | cut -d " " -f 3)
echo -e ${Yellow}default gateway:$NC
echo $defaultgateway


echo
netname=$(cat /etc/resolv.conf | grep search | cut -d " " -f 2)
echo -e ${Yellow}domain name:$NC
echo $netname

echo
fulliprange=$(ip -o -f inet addr show | awk '/scope global/ {print $2, $4}' | grep eth0 | cut -c 5-)
echo -e ${Yellow}full ip range:$NC
echo $fulliprange CIDR format

echo
firstipofrange=$(ipcalc $(echo $fulliprange) -nb | grep HostMin | cut -c 12- | cut -d ' ' -f 1)
laastipofrange=$(ipcalc $(echo $fulliprange) -nb | grep HostMax | cut -c 12- | cut -d ' ' -f 1)
echo -e ${Yellow}first ip-last ip:$NC
echo $firstipofrange-$laastipofrange

echo
echo -e ${Yellow}ip:$NC
echo $fulliprange | cut -d "/" -f 1


echo
echo -e ${Yellow}dhcpserver:$NC
echo "try 'sudo DHCPdump -i eth0' in other shell"
