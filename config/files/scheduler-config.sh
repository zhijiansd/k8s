#!/bin/bash
config()
{
export KUBE_APISERVER="https://192.168.100.180:8443"
cd /etc/kubernetes/

## 设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=scheduler.kubeconfig 

## 设置客户端认证参数
kubectl config set-credentials system:kube-scheduler \
  --client-certificate=/etc/kubernetes/ssl/scheduler.pem \
  --client-key=/etc/kubernetes/ssl/scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=scheduler.kubeconfig

## 设置关联参数
kubectl config set-context system:kube-scheduler \
  --cluster=kubernetes \
  --user=system:kube-scheduler \
  --kubeconfig=scheduler.kubeconfig

## 设置默认关联
kubectl config use-context system:kube-scheduler \
  --kubeconfig=scheduler.kubeconfig
}

copy-config()
{
  MASTER=(master1 master2)
  for node_name in ${MASTER[@]}
  do
    echo ">>> ${node_name}"
    scp /etc/kubernetes/scheduler.kubeconfig root@${node_name}:/etc/kubernetes/
  done
}

## 配置 scheduler.config 并复制至其他 master 节点
#LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`
LOCAL_ADDRESS=`ip addr|grep secondary|awk '{print $2}'|cut -c 1-15`
VIP='192.168.100.180'
if [ $LOCAL_ADDRESS == $VIP ];
then
    config
    copy-config
fi
