#!/bin/bash



onehonderd=100
nmapfilter="Nmap done|Starting Nmap|Stats|Ping|Timing|Not shown:|Host is up|Initiating|elapsed|Please report|Raw packets|Discovered open port|NSE|Retrying OS|Warning: OSScan results|Scanning|Read data files from|host down|Completed"

sudo apt install nmap gobuster ipcalc

fulliprange=$(ip -o -f inet addr show | awk '/scope global/ {print $2, $4}' | grep -v eth1 | cut -c 5-)
firstipofrange=$(ipcalc $(echo $fulliprange) -nb | grep HostMin | cut -c 12- | cut -d ' ' -f 1)
echo ip first: $firstipofrange



range=$(echo $firstipofrange | cut -d "." -f 1-3).$onehonderd
echo ip fullrange: $range


defaultbasicfolder=$firstipofrange-$onehonderd
rm -rf $defaultbasicfolder
mkdir -p $defaultbasicfolder


nmap $firstipofrange-$onehonderd | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapbasic.txt
nmap -p0- -v -A -T4 $firstipofrange-$onehonderd -Pn | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapadvanced.txt






currentfile=$defaultbasicfolder/basic/
macaddresfile=$defaultbasicfolder/macaddress.txt
rm -f $macaddresfile
rm -rf $currentfile
mkdir -p $currentfile

while read p ; do
if [[ $p != "" ]] ; then
    if [[ $p == *"Nmap scan report for"* ]] ; then
        curentip=$(echo $p | cut -d " " -f 5)
        currentfile=$defaultbasicfolder/basic/$curentip
        rm -rf $currentfile
        mkdir $currentfile
        currentfile=$currentfile/all
        touch $currentfile
        echo $curentip>>$defaultbasicfolder/iplist.txt
    fi
    if [[ $p == *"MAC Address"* ]] ; then
        echo "$p">>$macaddresfile
    fi
    echo "$p">>$currentfile
fi
done <$defaultbasicfolder/nmapbasic.txt




currentfile=$defaultbasicfolder/advanced/
rm -rf $currentfile
mkdir -p $currentfile

while read p ; do
if [[ $p != "" ]] ; then
    if [[ $p == *"Nmap scan report for"* ]] ; then
        curentip=$(echo $p | cut -d " " -f 5)
        currentfile=$defaultbasicfolder/advanced/$curentip
        rm -rf $currentfile
        mkdir $currentfile
        currentfile=$currentfile/all
        echo $curentip>>$defaultbasicfolder/iplist.txt
    fi
    if [[ $p == *"MAC Address"* ]] ; then
        echo "$p">>$macaddresfile
    fi
    echo "$p">>$currentfile
fi
done <$defaultbasicfolder/nmapadvanced.txt



function createPorts () {
    cat $1 | grep " open " | cut -d "/" -f 1 | while read line ; do sudo touch $(echo $f | sed 's/...$//')$line;done
}
for f in $defaultbasicfolder/*/*/txt; do createPorts $f; done


