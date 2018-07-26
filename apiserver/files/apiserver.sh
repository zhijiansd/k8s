#!/bin/bash
##截取IP
LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`

##配置变量
export ETCD_ENDPOINTS="https://192.168.100.181:2379,https://192.168.100.182:2379,https://192.168.100.183:2379,https://192.168.100.184:2379,https://192.168.100.185:2379"

##配置 kube-apiserver
cat << EOF > /etc/kubernetes/apiserver
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=0"

KUBE_ETCD_SERVERS="--etcd-servers=${ETCD_ENDPOINTS}"
KUBE_ETCD_CAFILE="--etcd-cafile=/etc/kubernetes/ssl/ca.pem"
KUBE_ETCD_CERTFILE="--etcd-certfile=/etc/kubernetes/ssl/etcd.pem"
KUBE_ETCD_KEYFILE="--etcd-keyfile=/etc/kubernetes/ssl/etcd-key.pem"

KUBE_API_ADDRESS="--advertise-address=${LOCAL_IP} --bind-address=${LOCAL_IP}"
KUBE_API_PORT="--secure-port=6443"

KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.244.0.0/16"
KUBE_ENABLE_ADMISSION_PLUGINS="--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"

KUBE_API_CLIENT_CA_FILE="--client-ca-file=/etc/kubernetes/ssl/ca.pem"
KUBE_API_SERVICE_ACCOUNT_KEY_FILE="--service-account-key-file=/etc/kubernetes/ssl/ca-key.pem"
 
KUBE_API_TLS_CERT_FILE="--tls-cert-file=/etc/kubernetes/ssl/apiserver.pem"
KUBE_API_TLS_PRIVATE_KEY_FILE="--tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem"

KUBELET_CLIENT_CERTIFICATE="--kubelet-client-certificate=/etc/kubernetes/ssl/apiserver.pem"
KUBELET_CLIENT_KEY="--kubelet-client-key=/etc/kubernetes/ssl/apiserver-key.pem"

KUBE_API_ARGS="--allow-privileged=true --anonymous-auth=false --apiserver-count=3 --audit-log-maxage=30 --audit-log-maxbackup=3 --audit-log-maxsize=100 --audit-log-path=/var/log/apiserver.log --authorization-mode=Node,RBAC --basic-auth-file=/etc/kubernetes/password.csv --enable-bootstrap-token-auth --enable-swagger-ui=true --event-ttl=1h --experimental-encryption-provider-config=/etc/kubernetes/encrypt-data.yaml --kubelet-https=true --service-node-port-range=30000-42767"
EOF

##配置通过http身份验证向API服务器的安全端口发出请求
##auth文件是一个至少包含3列的csv文件：密码，用户名，用户ID
echo admin,admin,1 > /etc/kubernetes/password.csv

##运行 kube-apiserver
systemctl daemon-reload
systemctl start kube-apiserver
systemctl enable kube-apiserver

