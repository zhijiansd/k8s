#!/bin/bash
##指定数据文件目录
mkdir -p /var/lib/kubelet

##配置kubelet
cat << EOF > /etc/kubernetes/kubelet
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"
NODE_HOSTNAME="--hostname-override=`hostname`"
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1"
KUBELET_ARGS="--bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.kubeconfig --cert-dir=/etc/kubernetes/ssl --config=/etc/kubernetes/kubelet-confing.yaml --kubeconfig=/etc/kubernetes/kubelet.kubeconfig"
EOF

##配置 kubelet-config
LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`
cat << EOF > /etc/kubernetes/kubelet-confing.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
evictionHard:
    memory.available:  "200Mi"  ##可用内存降至200Mi以下时驱逐Pods
address: "$LOCAL_IP"
authentication:
    x509:
         clientCAFile: "/etc/kubernetes/ssl/ca.pem"
    webhook:
            enabled: false
    anonymous:
           enabled: false
authorization:
    mode: AlwaysAllow
clusterDNS:
           - "10.244.0.2"
clusterDomain: "cluster.local"
cgroupDriver: cgroupfs
failSwapOn: false
hostnameOverride: `hostname`
hairpinMode: "promiscuous-bridge"
serializeImagePulls: false
syncFrequency: "1m"
logDir: "/var/log/kube"
port: 10250
RotateCertificates: true
featureGates:
    RotateKubeletClientCertificate: true
    RotateKubeletServerCertificate: true
EOF
