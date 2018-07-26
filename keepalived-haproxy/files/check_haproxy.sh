#!/bin/bash
if [ $(ps -C haproxy --no-header |wc -l) -eq 0 ]
then
    systemctl start haproxy
fi
sleep 2
if [ $(ps -C haproxy --no-header |wc -l) -eq 0 ]
then
    systemctl stop keepalived
fi
