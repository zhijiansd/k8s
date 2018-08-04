---
下载CoreDNS.yaml
---
```bash
# wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/coredns/coredns.yaml.base
# cp coredns.yaml.base coredns.yaml
```
---
修改相应配置
---
```bash
# sed -i "s/k8s.gcr.io/192.168.100.100\/coreos/g" coredns.yaml
# sed -i "s/__PILLAR__DNS__DOMAIN__/cluster.local/g" coredns.yaml
# sed -i "s/__PILLAR__DNS__SERVER__/10.244.0.2/g" coredns.yaml
```
---
创建CoreDNS
---
```bash
# kubectl apply -f coredns.yaml
serviceaccount/coredns configured
clusterrole.rbac.authorization.k8s.io/system:coredns configured
clusterrolebinding.rbac.authorization.k8s.io/system:coredns configured
configmap/coredns configured
deployment.extensions/coredns configured
service/kube-dns configured
```
---
查看CoreDNS
---
```bash
# kubectl get pod -n kube-system
NAME                       READY     STATUS    RESTARTS   AGE
coredns-84b5dddcdd-4tbqt   1/1       Running   0          5h
# kubectl cluster-info
Kubernetes master is running at https://192.168.100.180:8443
CoreDNS is running at https://192.168.100.180:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```
---
测试CoreDNS
---
+ 创建Pod
```bash
# vim my-nginx.yaml
apiVersion: extensions/v1beta1    
kind: Deployment                    
metadata:                           
  name: my-nginx                    
spec:                               
  replicas: 1                      
  template:                 
    metadata:               
      labels:              
        run: my-nginx       
    spec:
      containers:             
      - name: my-nginx           
        image: hub.c.163.com/library/nginx:1.13.0
        ports:                   
        - containerPort: 80         
---
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP       
# kubectl apply -f my-nginx.yaml 
deployment.extensions/my-nginx created
# kubectl get pod
NAME                       READY     STATUS    RESTARTS   AGE
my-nginx-87fb996b8-9xzb9   1/1       Running   0          20m
```

+ 测试CoreDNS
```bash
# kubectl exec my-nginx-87fb996b8-9xzb9 -- cat /etc/resolv.conf 
nameserver 10.244.0.2
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
# kubectl exec my-nginx-87fb996b8-9xzb9 -- ping -c 1 10.244.0.2
PING 10.244.0.2 (10.244.0.2): 56 data bytes
64 bytes from 10.244.0.2: icmp_seq=0 ttl=64 time=0.964 ms
# kubectl exec my-nginx-87fb996b8-9xzb9 -- ping -c 1 my-nginx
PING my-nginx.default.svc.cluster.local (10.244.107.1): 56 data bytes
64 bytes from 10.244.107.1: icmp_seq=0 ttl=64 time=0.459 ms
# kubectl exec my-nginx-87fb996b8-9xzb9 -- ping -c 1 kubernetes
PING kubernetes.default.svc.cluster.local (10.244.0.1): 56 data bytes
64 bytes from 10.244.0.1: icmp_seq=0 ttl=64 time=0.326 ms
```
