#!/bin/bash
                    T = 5
                    while $T
                    do
                        ansible get  -m script -a "/root/v2ray/v2ray_server_install.sh"
                        if [ "$?" = 0 ]
                        then
                                echo `date +"%Y-%m-%d %H:%M:%S"` "服务端脚本执行成功"
                                break
                        else
                                echo `date +"%Y-%m-%d %H:%M:%S"` "远程服务端脚本执行失败，重试"
                                T -=1
                        fi
                    done
