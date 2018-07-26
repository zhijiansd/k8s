#!/bin/bash
##设置相应变量
export ETCD_NAME=etcd-$(ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 13-15)
export LOCAL_IP=$(ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15)
export ETCD_CLUSTER="etcd-181=https://192.168.100.181:2380,etcd-182=https://192.168.100.182:2380,etcd-183=https://192.168.100.183:2380,etcd-184=https://192.168.100.184:2380,etcd-185=https://192.168.100.185:2380"

##配置etcd
cat << EOF > /etc/etcd/etcd.conf 
name: '${ETCD_NAME}'
heartbeat-interval: 2000     ##心跳间隔时间(以毫秒为单位)
election-timeout: 10000      ##超时选举时间,与心跳间隔时间至少5倍(以毫秒为单位)
data-dir: "/var/lib/etcd/"
listen-peer-urls: https://${LOCAL_IP}:2380
listen-client-urls: https://${LOCAL_IP}:2379,https://127.0.0.1:2379
initial-advertise-peer-urls: https://${LOCAL_IP}:2380
advertise-client-urls: https://${LOCAL_IP}:2379
initial-cluster: "${ETCD_CLUSTER}"
initial-cluster-token: 'etcd-cluster'
initial-cluster-state: 'new'   ##初始化集群状态('new' or 'existing')
client-transport-security:
  cert-file: /etc/kubernetes/ssl/etcd.pem
  key-file: /etc/kubernetes/ssl/etcd-key.pem
  trusted-ca-file: /etc/kubernetes/ssl/ca.pem
peer-transport-security:
  cert-file: /etc/kubernetes/ssl/etcd.pem
  key-file: /etc/kubernetes/ssl/etcd-key.pem
  trusted-ca-file: /etc/kubernetes/ssl/ca.pem
EOF

##启用etcd
systemctl daemon-reload
systemctl start etcd
systemctl enable etcd

