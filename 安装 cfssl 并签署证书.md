---
1.下载最新版cfssl
---
```bash
# go get -u github.com/cloudflare/cfssl/cmd/...
# cd go/bin/
# ls
cfssl  cfssl-bundle  cfssl-certinfo  cfssljson  cfssl-newkey  cfssl-scan  mkbundle  multirootca
# cp cfssl cfssljson /usr/bin/
# cfssl version
Version: 1.3.2
Revision: dev
Runtime: go1.9.4
```
---
2.生成ca证书和私钥
---
```bash
# mkdir cfssl && cd cfssl
# cat << EOF > ca_csr.json 
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
# cfssl gencert -initca ca_csr.json | cfssljson -bare ca
```
注:该命令生成运行CA所必需的文件ca-key.pem(私钥)和ca.pem(证书)，还会生成ca.csr(证书签名请求)，用于交叉签名或重新签名。
---
3.配置证书生成策略
---
```bash
# cat << EOF > ca_config.json 
{
  "signing": {
    "default": {
      "auth_key": "key1",
      "expiry": "87600h",
      "usages": [
         "signing",
         "key encipherment",
         "server auth",
         "client auth"
       ]
     }
  },
  "auth_keys": {
    "key1": {
      "key": "123456",
      "type": "standard"
    }
  }
}
EOF
```
注:该策略指定了证书有效期(10年)、用途(服务器验证等)以及一个随机生成的私有验证密钥(该密钥可以防止未经授权的机构请求证书)。
---
4.创建 apiserver 证书并生成其私钥
---
```bash
# cat << EOF > apiserver_csr.json
{
    "CN": "kubernetes",
    "hosts": [
      "127.0.0.1",
      "localhost",
      "10.244.0.1",
      "192.168.100.180",
      "192.168.100.181",
      "192.168.100.182",
      "192.168.100.183",
      "192.168.100.184",
      "192.168.100.185",
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
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca_config.json -profile=kubernetes apiserver_csr.json | cfssljson -bare apiserver
```
---
5.创建 Admin 证书并生成其私钥
---
```bash
# cat << EOF > admin_csr.json 
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
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca_config.json -profile=kubernetes admin_csr.json | cfssljson -bare admin
```
---
6.创建 Kube-controller-manager 证书并生成其私钥
---
```bash
# cat << EOF > controller-manager_csr.json
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "192.168.100.180",
      "192.168.100.181",
      "192.168.100.182"
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
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca_config.json -profile=kubernetes controller-manager_csr.json | cfssljson -bare controller-manager
```
---
7.创建 Kube-scheduler 证书并生成其私钥
---
```bash
# cat << EOF > scheduler_csr.json
{
    "CN": "system:kube-scheduler",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "192.168.100.180",
      "192.168.100.181",
      "192.168.100.182"
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
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca_config.json -profile=kubernetes scheduler_csr.json | cfssljson -bare scheduler
```
---
8.创建 Kube-Proxy 证书并生成其私钥
---
```bash
# cat << EOF > kube-proxy_csr.json
{
    "CN": "system:kube-proxy",
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
            "O": "k8s",
            "OU": "System"
        }
    ]
}
EOF
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca_config.json -profile=kubernetes  kube-proxy_csr.json | cfssljson -bare kube-proxy
```
---
9.创建 Etcd 证书并生成其私钥
---
```bash
# cat << EOF > etcd_csr.json
{
    "CN": "etcd",
    "hosts": [
      "127.0.0.1",
      "localhost",
      "192.168.100.181",
      "192.168.100.182",
      "192.168.100.183",
      "192.168.100.184",
      "192.168.100.185"
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
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca_config.json -profile=kubernetes  etcd_csr.json | cfssljson -bare etcd
```
---
10.校验证书
---
```bash
# openssl x509  -noout -text -in  apiserver.pem
# cfssl-certinfo -cert apiserver.pem
# openssl verify -CAfile ca.pem apiserver.pem
apiserver.pem: OK
# mkdir /root/ssl && cp *.pem /root/ssl
# ls /roo/ssl/
admin-key.pem  admin.pem  apiserver-key.pem  apiserver.pem  ca-key.pem  ca.pem  controller-manager-key.pem  controller-manager.pem  etcd-key.pem  etcd.pem  scheduler-key.pem  scheduler.pem
```
