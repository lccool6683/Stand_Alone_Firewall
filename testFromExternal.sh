#!/bin/sh

#User configuration section

#Print output to this file
outFile="./output"

#TCP ports to be accepted
tcp_port="80, 443"

#ICMP to be accepted
ICMP_port="8"

#Drop these ports
tcp_drop="111, 137, 138, 139, 515, 32768, 32769, 32770, 32771, 32772, 32773, 32774, 32775"

#Computer to ping
IPS="192.168.0.8"


#Do not modify this section

#Remove the output file if there is any
rm $outFile

echo "Initializing TCP ports $tcp_port that is allowed by user"
echo "" >> $outFile
echo "#Initializing TCP ports $tcp_port that is allowed by user" >> $outFile
echo "" >> $outFile
for protocol_port in $tcp_port
do
	echo "'$protocol_port' being added" >> $outFile;
	echo "" >> $outFile;
	`hping3 $IPS -c 1 --tcpexitcode -p $protocol_port -S &>> $outFile; `

done

echo "Initializing TCP ports $tcp_drop that is dropped by user"
echo "" >> $outFile
echo "#Initializing TCP ports $tcp_drop that is dropped by user" >> $outFile 
echo "" >> $outFile
for protocol_port in $tcp_drop
do
	echo "'$protocol_port' being dropped" >> $outFile;
	`hping3 $IPS -c 1 --tcpexitcode -p $protocol_port -S &>> $outFile;`
done

echo "Check the SYN to port 15000 on $IPS"
echo "" >> $outFile
echo "# Check the SYN to port 15000 on $IPS" >> $outFile
echo "" >> $outFile
protocol_port="15000"
 `hping3 $IPS -p $protocol_port -S -c 1 --tcpexitcode &>> $outFile; `

echo "Check the fragments in $IPS"
echo "" >> $outFile
echo "# Check the fragments in $IPS" >> $outFile
echo "" >> $outFile
for protocol_port in $tcp_port
do
	#Count the SYN and fin 
	 `hping3 $IPS -p $protocol_port -S -c 1 -f -d 888 --tcpexitcode &>> $outFile;`
done

echo "Waiting if $IPS will accept or drop SYN/FIN packets"
echo "" >> $outFile
echo "# Waiting if $IPS will accept or drop SYN/FIN packets" >> $outFile
echo "" >> $outFile
for protocol_port in $tcp_port
do
	 `hping3 $IPS -p $protocol_port -S -F -c 1 --tcpexitcode &>> $outFile; `
done

echo "Will $IPS drop telnet packets"
echo "" >> $outFile
echo "# Will $IPS drop telnet packets" >> $outFile
echo "" >> $outFile
protocol_port="23"
 `hping3 $IPS -p $protocol_port -S -c 1 --tcpexitcode &>> $outFile; `

echo "Scan the TCP ports on $IPS"
echo "" >> $outFile
echo "# Scan the TCP ports on $IPS" >> $$outFile
echo "" >> $outFile
nmap --top-ports 500 $IPS &>> $outFile;

echo "Will $IPS drop or accept ssh packets"
echo "" >> $outFile
echo "# Will $IPS drop or accpet ssh packets" >> $outFile
echo "" >> $outFile
protocol_port="22"
 `hping3 $IPS -p $protocol_port -S -c 1 --tcpexitcode &>> $outFile; `

echo "Testing ICMP from $IPS"
echo "" >> $outFile
echo "# Testing ICMP from $IPS" >> $outFile
echo "" >> $outFile
protocol_port = "22"
for icmp_p = $ICMP_port
	do
	`hping3 $IPS -p $protocol_port -S -c 1 -C $icmp_p --tcpexitcode &>> $outFile; `
done



