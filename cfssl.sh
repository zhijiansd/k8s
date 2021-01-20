#!/bin/bash

CONFIG='ca-config.json'
CSR='ca-csr.json'
SSLDIR='/root/ssl'
MASTER_VIP='192.168.100.150'
MASTER_IP1='192.168.100.139'
MASTER_IP2='192.168.100.140'
MASTER_IP3='192.168.100.141'
ETCD_IP1='192.168.100.136'
ETCD_IP2='192.168.100.137'
ETCD_IP3='192.168.100.138'
MASTER_CLUSTER_IP='10.244.0.1'

APISERVER_CSR='apiserver-csr.json'
APISERVER_KUBELET_CLIENT_CSR='apiserver-kubelet-client-csr.json'
CONTROLLER_MANAGER_CSR='controller-manager-csr.json'
SCHEDULER_CSR='scheduler-csr.json'
PROXY_CSR='proxy-csr.json'
ETCD_CSR='etcd-csr.json'
API_ETCD_CLIENT_CSR='apiserver-etcd-client-csr.json'
ETCD_CLIENT_CSR='etcd-client-csr.json'
METRICS_SERVER_CSR='metrics-server-csr.json'

API_BARENAME='apiserver'
APISERVER_KUBELET_CLIENT_BARENAME='apiserver-kubelet-client'
CONTROLLER_MANAGER_BARENAME='controller-manager'
SCHEDULER_BARENAME='scheduler'
PROXY_BARENAME='proxy'
ETCD_BARENAME='etcd'
API_ETCD_CLIENT_BARENAME='apiserver-etcd-client'
ETCD_CLIENT_BARENAME='etcd-client'
METRICS_SERVER_BARENAME='metrics-server'

set -x

## 生成CA文件

if [ ! -f ${CONFIG} ]; then
    cat << EOF > ${CONFIG} 
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
		    "client auth"			
                ]
            },		
            "etcd": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF
fi

## 生成CA证书签名请求(CSR)

if [ ! -f {$CSR} ]; then
   cat << EOF > ${CSR} 
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "ChengDu",
      "L": "ChengDu",
      "O": "K8S",
      "OU": "System"
    }
  ]
}
EOF
fi

# 生成 CA 密钥(ca-key.pem)和证书(ca.pem)

if [ -z ${SSLDIR} ]; then
    SSLDIR='${SSLDIR}'
fi

mkdir -p "${SSLDIR}"

if [ -e "${SSLDIR}/ca.pem" -a -e "${SSLDIR}/ca-key.pem" ]; then
    cp $SSLDIR/{ca.pem,ca-key.pem} .
else
cfssl gencert -initca ca-csr.json | cfssljson -bare ca > /dev/null 2>&1 
fi

# 创建用来为 Kube-apiserver 生成密钥和证书的 JSON 配置文件

if [ ! -f ${APISERVER_CSR} ]; then
   cat << EOF > ${APISERVER_CSR}
{
    "CN": "kube-apiserver",
    "hosts": [
      "127.0.0.1",
      "localhost",
      "${MASTER_VIP}",
      "${MASTER_IP1}",
      "${MASTER_IP2}",
      "${MASTER_IP3}",
      "${MASTER_CLUSTER_IP}",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "ChengDu",
            "L": "ChengDu",
            "O": "K8S",
            "OU": "System"
        }
    ]
}
EOF
fi

# 创建 Apiserver-Kubelet-client 证书
if [ ! -f ${APISERVER_KUBELET_CLIENT_CSR} ]; then
   cat << EOF > ${APISERVER_KUBELET_CLIENT_CSR}
{
    "CN": "kube-apiserver-kubelet-client",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "ChengDu",
            "L": "ChengDu",
            "O": "system:masters",
            "OU": "System"
        }
    ]
}
EOF
fi

# 创建用来为 Kube-controller-manager 生成密钥和证书的 JSON 配置文件

if [ ! -f ${CONTROLLER_MANAGER_CSR} ]; then
   cat << EOF > ${CONTROLLER_MANAGER_CSR}
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "localhost",
      "${MASTER_VIP}",
      "${MASTER_IP1}",
      "${MASTER_IP2}",
      "${MASTER_IP3}"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "ChengDu",
        "L": "ChengDu",
        "O": "system:kube-controller-manager",
        "OU": "System"
      }
    ]
}
EOF
fi

# 创建用来为 Kube-scheduler 生成密钥和证书的 JSON 配置文件

if [ ! -f ${SCHEDULER_CSR} ]; then
   cat << EOF > ${SCHEDULER_CSR}
{
    "CN": "system:kube-scheduler",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "localhost",
      "${MASTER_VIP}",
      "${MASTER_IP1}",
      "${MASTER_IP2}",
      "${MASTER_IP3}"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "ChengDu",
        "L": "ChengDu",
        "O": "system:kube-scheduler",
        "OU": "System"
      }
    ]
}
EOF
fi

# 创建用来为 Kube-proxy 生成密钥和证书的 JSON 配置文件

if [ ! -f ${PROXY_CSR} ]; then
   cat << EOF > ${PROXY_CSR}
{
    "CN": "system:kube-proxy",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [],
    "names": [
      {
        "C": "CN",
        "ST": "ChengDu",
        "L": "ChengDu",
        "O": "K8S",
        "OU": "System"
      }
    ]
}
EOF
fi

# 创建用来为 Metrics-server 生成密钥和证书的 JSON 配置文件

if [ ! -f ${METRICS_SERVER_CSR} ]; then
   cat << EOF > ${METRICS_SERVER_CSR}
{
    "CN": "aggregator",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ChengDu",
            "ST": "ChengDu",
            "O": "system:masters",
            "OU": "System"
        }
    ]
}
EOF
fi

# 创建用来为 etcd-server 生成密钥和证书的 JSON 配置文件

if [ ! -f ${ETCD_CSR} ]; then
   cat << EOF > ${ETCD_CSR}
{
    "CN": "etcd-server",
    "hosts": [
      "localhost",
      "127.0.0.1",
      "${ETCD_IP1}",
      "${ETCD_IP2}",
      "${ETCD_IP3}"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ChengDu",
            "ST": "ChengDu",
            "O": "etcd",
            "OU": "etcd-server"
        }
    ]
}
EOF
fi

# 创建用来为 apiserver-etcd-client 生成密钥和证书的 JSON 配置文件

if [ ! -f ${API_ETCD_CLIENT_CSR} ]; then
   cat << EOF > ${API_ETCD_CLIENT_CSR}
{
    "CN": "apiserver-etcd-client",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ChengDu",
            "ST": "ChengDu",
            "O": "system:masters",
            "OU": "apiserver-etcd-client"
        }
    ]
}
EOF
fi

# 创建用来为 etcd-client 生成密钥和证书的 JSON 配置文件

if [ ! -f ${ETCD_CLIENT_CSR} ]; then
   cat << EOF > ${ETCD_CLIENT_CSR}
{
    "CN": "etcd-client",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "ChengDu",
            "ST": "ChengDu",
            "O": "etcd",
            "OU": "etcd-client"
        }
    ]
}
EOF
fi

# 为 Kube-apiserver 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${APISERVER_CSR} | cfssljson -bare ${API_BARENAME} > /dev/null 2>&1 

# 为 Apiserver-Kubelet-client 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${APISERVER_KUBELET_CLIENT_CSR} | cfssljson -bare ${APISERVER_KUBELET_CLIENT_BARENAME} > /dev/null 2>&1 

# 为 Kube-controller-manager 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${CONTROLLER_MANAGER_CSR} | cfssljson -bare ${CONTROLLER_MANAGER_BARENAME} > /dev/null 2>&1 

# 为 Kube-scheduler 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${SCHEDULER_CSR} | cfssljson -bare ${SCHEDULER_BARENAME} > /dev/null 2>&1 

# 为 Kube-proxy 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${PROXY_CSR} | cfssljson -bare ${PROXY_BARENAME} > /dev/null 2>&1 

# 为 Metrics-server 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${METRICS_SERVER_CSR} | cfssljson -bare ${METRICS_SERVER_BARENAME} > /dev/null 2>&1 

# 为 etcd-server 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=etcd \
${ETCD_CSR} | cfssljson -bare ${ETCD_BARENAME} > /dev/null 2>&1

# 为 apiserver-etcd-client 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=etcd \
${API_ETCD_CLIENT_CSR} | cfssljson -bare ${API_ETCD_CLIENT_BARENAME} > /dev/null 2>&1

# 为 etcd-client 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=etcd \
${ETCD_CLIENT_CSR} | cfssljson -bare ${ETCD_CLIENT_BARENAME} > /dev/null 2>&1

if [ -e "${SSLDIR}/ca.pem" -a -e "${SSLDIR}/ca-key.pem" ]; then
     rm -f ca.pem ca-key.pem
fi

mv *.pem ${SSLDIR}/
