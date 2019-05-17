#!/bin/bash 
VIP=10.24.1.20
#/etc/rc.d/init.d/functions 
case "$1" in 
start) 
           echo "start LVS of RealServer DR" 
           /sbin/ifconfig lo:0 $VIP broadcast $VIP netmask 255.255.255.255 up 
           /sbin/route add -host $VIP dev lo:0  
           echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore 
           echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce 
           echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore 
           echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce  
       ;; 
stop) 
           /sbin/ifconfig lo:0 down 
           echo "close LVS of RealServer DR" 
           echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore 
           echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce 
           echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore 
           echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce 
           ;; 
  
*) 
          echo "Usage: $0 {start|stop}" 
          exit 1 
esac  
exit 0
