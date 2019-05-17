#!/bin/bash

while true
do
#    local_ip=`ifconfig |  grep -v ens160:0 |sed -n '/\bens160\b/{n;p}'| awk '{print$2}'|awk -F':' '{print$2}'`
    local_ip=`ifconfig |  grep -E "inet addr:10.24.1.25"|awk '{print$2}'|awk -F ':' '{print$2}'`
    v_count=`service v2ray status| grep -E "running" | wc -l`
    d_count=`service dnsmasq status | grep -E "running" | wc -l`

    tkp(){
        k_count=`service keepalived status | grep -E "running" | wc -l`
        if [ $k_count -eq 0 ]
            then
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "keepalived服务未启动"
            service keepalived start
            if [ $? -gt 0 ]
            then
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "keepalived启动失败"
                exit 1
            else
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "keepalived启动成功"
            fi
            else
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "keepalived服务已启动"
        fi
    }

    kbandusage(){
        # 监控vlutr的使用率，达到290G时候暂停keepalived服务
        key="API-Key: QYLPNWSVQW6KQSJD4ES3R3QDZXMJD3IXIK2A"
        MONITOR_IP=`cat /etc/v2ray/config.json | grep "address"| sed -n '1p' | awk -F '"' '{print$4}'`
        echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "本地使用的v2ray服务器地址为 $MONITOR_IP"

        curl -H "$key" https://api.vultr.com/v1/server/list | python -m json.tool | grep  -E "\blabel\b|\bSUBID\b|\bmain_ip\b" | awk '{print$1 $2}' > serverlist.log

        MONITOR_SUBID=`cat serverlist.log | grep -E "\bSUBID\b|\bmain_ip\b" |sed -n "/$MONITOR_IP/{x;p};h" | awk -F '"' '{print$4}'`
        echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "本地使用的v2ray服务器的subid为$MONITOR_SUBID"
        rm serverlist.log
        #获取宽带使用量
        curl -H "$key" https://api.vultr.com/v1/server/bandwidth?SUBID=$MONITOR_SUBID | python -m json.tool > log1
        all_count=`cat log1 |wc -l`
        half_count=`expr $all_count / 2`
        cat log1 | grep -A $half_count "outgoing_bytes"  > log2
        rm log1
        sed -i '$d' log2
        sed -i '1d' log2
        sed -i '$d' log2
        sed -i '/,/d' log2
        sed -i '1~2d' log2
        BANDWIDTH=`awk -F '"' '{sum+=$2};END {print sum}' log2`
        rm log2
        echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "获取v2ray服务器宽带使用率为 $BANDWIDTH 字节"
        if [ -z "$BANDWIDTH" ]
        then
            echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "跳出本次监控"
            sleep 5
            continue
        else
            i=`expr 1024 \* 1024 \* 1024`
            BANDUSAGE=`echo "sclae=2;$BANDWIDTH/$i" | bc`
            echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "宽带使用率为$BANDUSAGE  G"

            if [ $BANDUSAGE -gt 100 ]
            then
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "触发暂停keepalived条件， keepalived 服务将停用"
                service keepalived stop
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "keepalived服务暂停成功"
            else
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "检查keepalived服务"
                tkp
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "流量小于250GG,进行下一次监控循环"
            fi
        fi
        sleep 300
    }


    if [ $v_count -eq 0 ]
    then
        service v2ray start
        if [ $? -gt 0 ]
            then
                echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "v2ray服务启动失败，请检查,停止keepalived服务"
            service keepalived stop
            exit 1
        fi
    fi


    if [ $d_count -eq 0 ]
    then
        service dnsmasq start
        if [ $? -gt 0 ]
        then
            echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "dnsmasq服务启动失败，请检查"
        service keepalived stop
        fi
    fi


    dig @127.0.0.1   www.google.com > dig.log
    QUERY_TIME=`cat dig.log | grep -E "Query time" | awk -F ':' '{print$2}' | awk '{print$1}'`
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "开始解析，解析时间为$QUERY_TIME"
    TTL_TIME=`cat dig.log | sed -n '/ANSWER SECTION/{n;p}'| awk '{print$2}'`
    echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "缓存时间为$TTL_TIME"
    CONNECTION_TIME_OUT=`cat dig.log | grep -E "connection timed out" | wc -l`
    rm dig.log

    if [ $CONNECTION_TIME_OUT -gt 0 ]
    then
            echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "解析超时，本地使用的v2ray服务器dns解析异常，停用keepalived 服务,发送邮件通知"
            service keepalived stop
        continue
    fi


    if [ $QUERY_TIME -eq 0 ]
    then
            echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "当前使用的是缓存解析，等待ttl时间后，重新测试dns解析"
            sleep $TTL_TIME
            sleep 1
            echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "TTL时间已过，重新解析dns,本次解析结束"
            continue
    else
        echo `date +"%Y-%m-%d %H:%M:%S"` $local_ip "dns解析正常"
        tkp
        kbandusage
    fi
done
