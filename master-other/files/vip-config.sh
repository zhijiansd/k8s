#!/bin/bash
config()
{
## 启动 apiserver 后将 admin 用户和 cluster-admin 绑定
kubectl create clusterrolebinding login-on-dashboard-with-cluster-admin \
  --clusterrole=cluster-admin --user=admin

## 赋予 system:bootstrappers 用户组 system:node-bootstrapper 集群角色(role)
## 使 kubelet 有权限创建认证请求(certificate signing requests)
kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --group=system:bootstrappers

## 配置 Approval controller 审批控制器
kubectl create -f /etc/kubernetes/tls-bootstrapping.yaml

## 授权 CN=kubernetes 的客户端证书连接到 kubelet API
kubectl create clusterrolebinding apiserver-kubelet-api-admin \
  --clusterrole system:kubelet-api-admin \
  --user kubernetes
}

## 配置使 flannel 使用 etcd
etcd-flanneld()
{
 etcdctl --endpoints=https://192.168.100.181:2379 mkdir /kube/network
 etcdctl --endpoints=https://192.168.100.181:2379 set /kube/network/config '{ "Network": "10.244.0.0/16" }'
}

LOCAL_ADDRESS=`ip addr|grep secondary|awk '{print $2}'|cut -c 1-15`
VIP='192.168.100.180'
if [ $LOCAL_ADDRESS == $VIP ];
then
    config
    etcd-flanneld
fi
