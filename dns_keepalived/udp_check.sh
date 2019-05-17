#!/bin/bash

while true
do
	service dnsmasq start
	count=`ps -ef | grep dnsmasq | grep -v grep|wc -l`
	if [ $count -gt 0 ]
	then
		service nginx start
		echo "dnsmasq started success"
	else
		service nginx stop
		echo "dnsmasq started failed"
	fi
done
