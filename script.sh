#!/bin/bash

if true; then

#prereqs
sudo apt install nmap gobuster ipcalc



# nmap setup
onehonderd=100
nmapfilter="Nmap done|Starting Nmap|Stats|Ping|Timing|Not shown:|Host is up|Initiating|elapsed|Please report|Raw packets|Discovered open port|NSE|Retrying OS|Warning: OSScan results|Scanning|Read data files from|host down|Completed"



fulliprange=$(ip -o -f inet addr show | awk '/scope global/ {print $2, $4}' | grep -v eth1 | cut -c 5-)
firstipofrange=$(ipcalc $(echo $fulliprange) -nb | grep HostMin | cut -c 12- | cut -d ' ' -f 1)
echo ip first: $firstipofrange


##nmap actual scan
range=$(echo $firstipofrange | cut -d "." -f 1-3).$onehonderd
echo ip fullrange: $range
defaultbasicfolder=$firstipofrange-$onehonderd
rm -rf $defaultbasicfolder
mkdir -p $defaultbasicfolder
nmap $firstipofrange-$onehonderd | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapbasic.txt
nmap -p0- -v -A -T4 $firstipofrange-$onehonderd -Pn | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapadvanced.txt

##TODO add single host scan 192.168.110.10


##nmap making ports visible
currentfile=$defaultbasicfolder/basic/
macaddresfile=$defaultbasicfolder/macaddress.lst
iplistfile=$defaultbasicfolder/iplist.lst
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
        echo $curentip>>$iplistfile
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
        echo $curentip>>$iplistfile
    fi
    if [[ $p == *"MAC Address"* ]] ; then
        echo "$p">>$macaddresfile
    fi
    echo "$p">>$currentfile
fi
done <$defaultbasicfolder/nmapadvanced.txt


## making ports files
function createPorts () {
    cat $1 | grep " open " | cut -d "/" -f 1 | while read line ; do sudo touch $(echo $f | sed 's/...$//')$line;done
}
for f in $defaultbasicfolder/*/*/all; do createPorts $f; done

## filterfiles

function filterfiles() {
    cat $1 | sort | uniq > $1.filt
    mv $1.filt $1
}

filterfiles ${iplistfile}
filterfiles ${macaddresfile}

# cat ${iplistfile} | sort | uniq > ${iplistfile}.filt
# cat ${macaddresfile} | sort | uniq > ${macaddresfile}.filt



## TODO: combine advanced and basic
for i in $defaultbasicfolder/basic/*/all; do mv "$i" "$i"---basic; done
for i in $defaultbasicfolder/advanced/*/all; do mv "$i" "$i"---advanced; done
mkdir -p $defaultbasicfolder/combined
cp -rf $defaultbasicfolder/basic/* $defaultbasicfolder/combined/
cp -rf $defaultbasicfolder/advanced/* $defaultbasicfolder/combined/
rm -rf $defaultbasicfolder/basic/
rm  -rf $defaultbasicfolder/advanced/



## dns check if dns zonetransfer possibility
cat /etc/resolv.conf | grep -v "#" > $defaultbasicfolder/dnsserver.txt
netname=$(cat $defaultbasicfolder/dnsserver.txt | grep search | cut -d " " -f 2)
netip=$(cat $defaultbasicfolder/dnsserver.txt | grep nameserver | cut -d " " -f 2)
zoneTransferAble=$(dig axfr $netname @$netip)

dig axfr $netname @$netip >> $defaultbasicfolder/dnsserver.txt
# ## TODO: vragen hoe te weten of dit waar is

if [[ $zoneTransferAble =~ .*"failed: connection refused".* ]]
then
    mv $defaultbasicfolder/dnsserver.txt "$defaultbasicfolder/dnsserver---failed-connection.txt"
elif [[ $zoneTransferAble =~ .*"Transfer failed".* ]]
then
    mv $defaultbasicfolder/dnsserver.txt "$defaultbasicfolder/dnsserver---failed-transfer.txt"
else
    mv $defaultbasicfolder/dnsserver.txt "$defaultbasicfolder/dnsserver---working-zone-transfer-attack-probably.txt"
fi




fi
defaultbasicfolder="./192.168.52.1-100"



# ## fileshare

sharefolder="${defaultbasicfolder}/shares"
mkdir -p $sharefolder
function checkfileshares() {
    FILE="${1}"
    if [[ -f "${FILE}139" ]] && [[ -f "${FILE}445" ]]; then
        ip=$(echo "${FILE#./}" | cut -d "/" -f 3)
        smbfile="$sharefolder/${ip}"
        mkdir -p $smbfile
        smbclient -L \\$ip\\ -U anonymous -N > ${smbfile}/all
        if grep -q 'session setup failed' ${smbfile}/all; then
            rm -rf ${smbfile}
        else
            cat ${smbfile}/all | grep -a -v -E "Reconnecting|Unable|---------\s*----\s*-------|Sharename\s*Type\s*Comment" | awk '{$1=$1;print}' | cut -d " " -f 1 > ${smbfile}/all.dbs
            while read p ; do
                if [[ $p != "" ]] ; then
                    smbclient \\\\$ip\\$p -U anonymous -N -c "dir" | grep -a -v -E "blocks available|\s\.\s|\s\.\.\s" | awk '{$1=$1;print}' > ${smbfile}/all.dbs_${p}

                    if grep -a -q -E "NT_STATUS_ACCESS_DENIED|NT_STATUS_NO_SUCH_FILE" ${smbfile}/all.dbs_${p}; then
                        rm -rf ${smbfile}/all.dbs_${p}
                    else
                        echo "try:
smbclient \\\\\\\\${ip}\\\\${p} -U anonymous -N
dir
get filex" >> ${smbfile}/all.dbs_${p}
                    fi
                fi
            done <${smbfile}/all.dbs
        fi
    fi
}
for f in $defaultbasicfolder/combined/*/; do checkfileshares $f; done

# vragen of examen ook met pokemons gaat zijn of niet
