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
  --kubeconfig=kube-proxy.kubeconfig

## 设置客户端认证参数
kubectl config set-credentials kube-proxy \
  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

## 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
  
## 设置默认上下文
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig  
}

copy-config()
{
  NODE=(node01 node02 node03)
  for node_name in ${NODE[@]}
  do
    echo ">>> ${node_name}"
    scp /etc/kubernetes/kube-proxy.kubeconfig root@${node_name}:/etc/kubernetes/
  done
}

##配置 kube-proxy.kubeconfig
#LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`
LOCAL_ADDRESS=`ip addr|grep secondary|awk '{print $2}'|cut -c 1-15`
VIP='192.168.100.180'
if [ $LOCAL_ADDRESS == $VIP ];
then
    config
    copy-config
fi
