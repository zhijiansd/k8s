#!/bin/bash
LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`

##配置kube-proxy
cat << EOF > /etc/kubernetes/proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
hostnameOverride: `hostname`
bindAddress: $LOCAL_IP
clusterCIDR: 10.244.0.0/16 
clientConnection:
    kubeconfig: /etc/kubernetes/kube-proxy.kubeconfig
logDir: "/var/log/kube"
#mode: iptables
mode: "ipvs"
featureGates:
    SupportIPVSProxyMode: true
EOF
