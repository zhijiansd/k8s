#!/bin/bash
## 配置变量
config()
{
export KUBE_APISERVER="https://192.168.100.180:8443"
cd /root/

## 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} 

## 设置客户端认证参数
kubectl config set-credentials admin \
  --client-certificate=/etc/kubernetes/ssl/admin.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/admin-key.pem

## 设置关联参数
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin

## 设置默认关联
kubectl config use-context kubernetes
}

copy-config()
{
  MASTER=(master1 master2)
  for node_name in ${MASTER[@]}
  do
    echo ">>> ${node_name}"
    scp /root/.kube/config root@${node_name}:/root/.kube/config
  done
}

## 配置 kubeconfig并复制至其他 master
#LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`
LOCAL_ADDRESS=`ip addr|grep secondary|awk '{print $2}'|cut -c 1-15`
VIP='192.168.100.180'
if [ $LOCAL_ADDRESS == $VIP ];
then
    config
    copy-config
fi
