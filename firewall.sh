#!/bin/bash

#User configuration
#This section shall be edited

host_ipaddr="192.168.10.1"; #The firewall
internal_ipaddr="192.168.10.2"; #The computer connected to the firewall
network_ipaddr="192.168.10.0/24" #The subnet
inside_interface="enp3s2";
out_interface="eno1";


tcp_port='22,53,67,68,80,443'
udp_port='22,53,67,80,443'
ALLOW_ICMP="8 0"



#DEFAULT POLICIES DROPPED
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

#All packets from the outside dropped
iptables -A INPUT -i $out_interface -d $host_ipaddr -j DROP 

#Drop packets that have the same source address from the outside
iptables -A FORWARD -s $network_ipaddr -i $out_interface -j DROP 

#All tcp packets that have the SYN and FIN bit set dropped
iptables -A FORWARD -p tcp -i $out_interface -o $inside_interface --tcp-flags SYN,FIN SYN,FIN -j DROP

#Block Incoming traffic to these ports
#Priority rule TCP


iptables -A FORWARD -p tcp -i $out_interface -o $inside_interface --dport 32768:32775 -j DROP -m state --state NEW,ESTABLISHED 

iptables -A FORWARD -p tcp -i $out_interface -o $inside_interface --dport 137:139 -j DROP -m state --state NEW,ESTABLISHED 

iptables -A FORWARD -p tcp -i $out_interface -o $inside_interface -m multiport --dport 111,515 -j DROP -m state --state NEW,ESTABLISHED


#Priority rule for UDP
iptables -A FORWARD -p udp -i $out_interface -o $inside_interface --dport 32768:32775 -j DROP -m state --state NEW,ESTABLISHED 

iptables -A FORWARD -p udp -i $out_interface -o $inside_interface --dport 137:139 -j DROP -m state --state NEW,ESTABLISHED 

#Reject  telnet connections
iptables -A FORWARD -p tcp --sport 23 -j DROP
iptables -A FORWARD -p tcp --dport 23 -j DROP

#Accept fragments
iptables -A FORWARD -p tcp -i $inside_interface -o $out_interface -m state --state NEW -f -j ACCEPT -m state --state NEW,ESTABLISHED
iptables -A FORWARD -p tcp -o $inside_interface -i $out_interface  -m state --state NEW -f -j ACCEPT -m state --state NEW,ESTABLISHED
iptables -A FORWARD -p udp -i $inside_interface -o $out_interface -m state --state NEW -f -j ACCEPT -m state --state NEW,ESTABLISHED
iptables -A FORWARD -p udp -o $inside_interface -i $out_interface  -m state --state NEW -f -j ACCEPT -m state --state NEW,ESTABLISHED


#Accept the tcp ports implemented by user
iptables -A FORWARD -p TCP -m multiport --sport 1024:65535 -m multiport --dport $tcp_port -j ACCEPT -m state  --state NEW,ESTABLISHED
iptables -A FORWARD -p TCP -m multiport --sport $tcp_port -m multiport --dport 1024:65535 -j ACCEPT -m state  --state NEW,ESTABLISHED


#Accept the udp ports implemented by user
iptables -A FORWARD -p udp -m multiport --sport 1024:65535 -m multiport --dport $udp_port -j ACCEPT -m state  --state NEW,ESTABLISHED
iptables -A FORWARD -p udp -m multiport --sport $udp_port -m multiport --dport 1024:65535 -j ACCEPT -m state  --state NEW,ESTABLISHED




#Accept ICMP
#For each ICMP port in user config


for i in $ALLOW_ICMP
do	
	iptables -A FORWARD -p ICMP -i $out_interface -o $inside_interface --icmp-type $i -j ACCEPT -m state --state new,established
	iptables -A FORWARD -p ICMP -i $inside_interface -o $out_interface --icmp-type $i -j ACCEPT -m state --state new,established
done



#Allow SSH, FTP data and FTP
	iptables -A FORWARD -p TCP -m multiport --sport 1024:65535 -m multiport --dport 20,21,22 -j ACCEPT -m state --state new,established
	iptables -A FORWARD -p TCP -m multiport --dport 1024:65535 -m multiport --sport 20,21,22 -j ACCEPT -m state --state new,established

#Postrouting
iptables -t nat -A POSTROUTING -s $network_ipaddr -o $out_interface -j SNAT --to-source $host_ipaddr

#Prerouting
iptables -t nat -A PREROUTING -i $out_interface -j DNAT --to-destination $internal_ipaddr 

#Set ssh connection to minimum delay
iptables -A PREROUTING -t mangle -p tcp --sport ssh  -j TOS --set-tos Minimize-Delay

#Set ftp connection to minimum delay
iptables -A PREROUTING -t mangle -p tcp --sport ftp -j  TOS --set-tos Minimize-Delay

#Set ftp-data control connection to maximum throughput
iptables -A PREROUTING -t mangle -p tcp --sport ftp-data -j  TOS --set-tos Maximize-Throughput


echo "IP tables implemented";


