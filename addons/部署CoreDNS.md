## 下载CoreDNS.yaml

```bash
wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/dns/coredns/coredns.yaml.base -O coredns.yaml
```

## 修改相应配置

```bash
sed -i "s/__PILLAR__DNS__DOMAIN__/cluster.local/g" coredns.yaml
sed -i "s/__PILLAR__DNS__SERVER__/10.244.0.2/g" coredns.yaml
sed -i "s/__PILLAR__DNS__MEMORY__LIMIT__/140Mi/g" coredns.yaml
```

## 部署CoreDNS

```bash
# kubectl apply -f coredns.yaml 
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created
```

## 查看CoreDNS

```bash
# kubectl get pod -n kube-system
NAME                              READY   STATUS    RESTARTS   AGE
coredns-5b567c58d6-gfr58          1/1     Running   0          28h
# kubectl cluster-info
Kubernetes master is running at https://192.168.100.150:8443
CoreDNS is running at https://192.168.100.150:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```


