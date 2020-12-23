## 下载文件

```bash
git clone https://github.com/kubernetes-sigs/metrics-server.git
```

## 部署之前所需配置

### kube-apiserver

```bash
--requestheader-allowed-names=aggregator
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
metricsBindAddress: nodeip
metricsPort: 10249
```

## 修改相应配置

```bash
# cd metrics-server/deploy/1.8+/
# vim metrics-server-deployment.yaml
      containers:
      - name: metrics-server
        image: 192.168.100.100/kubernetesui/metrics-server-amd64:v0.3.6
        command:
          - /metrics-server
          - --kubelet-insecure-tls
          - --kubelet-preferred-address-types=InternalIP
```

## 部署Metrics-server

```bash
# kubectl apply -f .
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
serviceaccount/metrics-server created
deployment.apps/metrics-server created
service/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
```

## 查看Metrics-server

```bash
# kubectl get pod -n kube-system | grep metrics-server
metrics-server-59fc876954-8jf8f   1/1     Running   0          28h
# kubectl cluster-info
Kubernetes master is running at https://192.168.100.150:8443
CoreDNS is running at https://192.168.100.150:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
Metrics-server is running at https://192.168.100.150:8443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy
# kubectl top node
NAME    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
node1   168m         2%     792Mi           14%       
node2   120m         1%     1081Mi          19%       
node3   195m         2%     1096Mi          19%       
```

