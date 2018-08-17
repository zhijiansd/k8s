---
下载相关yaml文件(根据情况更改镜像地址)
---
```bash
# wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/es-statefulset.yaml
# wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/es-service.yaml
# wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/kibana-deployment.yaml
# wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/kibana-service.yaml
# wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/fluentd-es-ds.yaml
# wget https://raw.githubusercontent.com/kubernetes/kubernetes/master/cluster/addons/fluentd-elasticsearch/fluentd-es-configmap.yaml
```
---
为所有节点打标签
---
```bash
kubectl label nodes --all beta.kubernetes.io/fluentd-ds-ready=true
```
---
部署fluentd-elasticsearch
---
kubectl apply -f .
# kubectl get pods -n kube-system -o wide|egrep 'elasticsearch|fluentd|kibana'
elasticsearch-logging-0                 1/1       Running   0          5h       10.244.91.3    node02
elasticsearch-logging-1                 1/1       Running   0          5h       10.244.88.4    node03
fluentd-es-v2.2.0-867fs                 1/1       Running   0          5h       10.244.91.4    node02
fluentd-es-v2.2.0-9qjxq                 1/1       Running   0          5h       10.244.67.10   node01
fluentd-es-v2.2.0-bzrl9                 1/1       Running   1          5h       10.244.88.3    node03
kibana-logging-6d6dd577d6-qnb77         1/1       Running   0          5h       10.244.91.5    node02
# kubectl cluster-info|egrep 'Elasticsearch|Kibana'
Elasticsearch is running at https://192.168.100.180:8443/api/v1/namespaces/kube-system/services/elasticsearch-logging/proxy
Kibana is running at https://192.168.100.180:8443/api/v1/namespaces/kube-system/services/kibana-logging/proxy
