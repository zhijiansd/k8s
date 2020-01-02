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
ADMIN_CSR='admin-csr.json'
CONTROLLER_MANAGER_CSR='controller-manager-csr.json'
SCHEDULER_CSR='scheduler-csr.json'
PROXY_CSR='proxy-csr.json'
ETCD_CSR='etcd-csr.json'
CLIENT_CSR='etcd-client-csr.json'

API_BARENAME='apiserver'
ADMIN_BARENAME='admin'
CONTROLLER_MANAGER_BARENAME='controller-manager'
SCHEDULER_BARENAME='scheduler'
PROXY_BARENAME='proxy'
ETCD_BARENAME='etcd'
CLIENT_BARENAME='etcd-client'

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
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
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
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
fi

# 生成 CA 密钥（ca-key.pem）和证书（ca.pem）

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
    "CN": "kubernetes",
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
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
fi

# 创建 Admin 证书
if [ ! -f ${ADMIN_CSR} ]; then
   cat << EOF > admin-csr.json 
{
    "CN": "admin",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
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
      "${MASTER_VIP}",
      "${MASTER_IP1}",
      "${MASTER_IP2}",
      "${MASTER_IP3}"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
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
      "${MASTER_VIP}",
      "${MASTER_IP1}",
      "${MASTER_IP2}",
      "${MASTER_IP3}"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
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
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "k8s",
        "OU": "System"
      }
    ]
}
EOF
fi

# 创建用来为 etcd server 生成密钥和证书的 JSON 配置文件

if [ ! -f ${ETCD_CSR} ]; then
   cat << EOF > ${ETCD_CSR}
{
    "CN": "etcd",
    "hosts": [
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
            "L": "BeiJing",
            "ST": "BeiJing",
            "O": "k8s",
            "OU": "etcd"
        }
    ]
}
EOF
fi

# 创建用来为 etcd client 生成密钥和证书的 JSON 配置文件

if [ ! -f ${CLIENT_CSR} ]; then
   cat << EOF > ${CLIENT_CSR}
{
    "CN": "client",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing",
            "O": "k8s",
            "OU": "etcd"
        }
    ]
}
EOF
fi

# 为 Kube-apiserver 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${APISERVER_CSR} | cfssljson -bare ${API_BARENAME} > /dev/null 2>&1 

# 为 Admin 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=kubernetes \
${ADMIN_CSR} | cfssljson -bare ${ADMIN_BARENAME} > /dev/null 2>&1 

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

# 为 etcd server 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=etcd \
${ETCD_CSR} | cfssljson -bare ${ETCD_BARENAME} > /dev/null 2>&1

# 为 etcd client 生成密钥和证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=${CONFIG} -profile=client \
${CLIENT_CSR} | cfssljson -bare ${CLIENT_BARENAME} > /dev/null 2>&1


if [ -e "${SSLDIR}/ca.pem" -a -e "${SSLDIR}/ca-key.pem" ]; then
     rm -f ca.pem ca-key.pem
fi

mv *.pem ${SSLDIR}/

