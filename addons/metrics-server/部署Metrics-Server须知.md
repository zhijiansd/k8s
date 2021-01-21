---
部署之前所需配置
---

### 聚合层证书签署

```bash
# vim metrics-server-csr.json 
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
            "OU": "metrics-server"
        }
    ]
}
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem \
--config=ca-config.json -profile=kubernetes \
metrics-server-csr.json | cfssljson -bare metrics-server
```

> 注:聚合层证书除了O(组织)必须为"system:masters"外，其他都可以根据实际情况更改。

### kube-apiserver

```bash
--proxy-client-cert-file=/etc/ssl/kubernetes/metrics-server.pem
--proxy-client-key-file=/etc/ssl/kubernetes/metrics-server-key.pem
--requestheader-allowed-names
--requestheader-client-ca-file=/etc/ssl/kubernetes/ca.pem
--requestheader-extra-headers-prefix=X-Remote-Extra- 
--requestheader-group-headers=X-Remote-Group 
--requestheader-username-headers=X-Remote-User
--enable-aggregator-routing
```

### kube-controller-manager

```bash
--requestheader-allowed-names
--requestheader-client-ca-file=/etc/ssl/kubernetes/ca.pem
--requestheader-extra-headers-prefix=X-Remote-Extra- 
--requestheader-group-headers=X-Remote-Group 
--requestheader-username-headers=X-Remote-User
```

### kube-scheduler

```bash
--requestheader-allowed-names
--requestheader-client-ca-file=/etc/ssl/kubernetes/ca.pem
--requestheader-extra-headers-prefix=X-Remote-Extra- 
--requestheader-group-headers=X-Remote-Group 
--requestheader-username-headers=X-Remote-User
```

### kubelet

```bash
# vim /etc/kubernetes/kubelet-confing.yaml
authentication:
    x509:
         clientCAFile: /etc/ssl/kubernetes/ca.pem
    webhook:
            enabled: true
    anonymous:
           enabled: false
authorization:
    mode: Webhook
```

### kube-proxy

```bash
# vim /etc/kubernetes/proxy-confing.yaml
metricsBindAddress: NodeIP:10249
metricsPort: 10249
```

### 官方yaml文件修改

```bash
# vim metrics-server.yaml
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
---

> 官方配置聚合层的文档:https://kubernetes.io/zh/docs/tasks/extend-kubernetes/configure-aggregation-layer/

> 二进制安装的master节点也需要安装containerd、kubelet、kube-proxy才能采集指标
