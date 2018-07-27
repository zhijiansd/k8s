---
使用ansible部署kubernetes集群
---
Master节点
---
+ 192.168.100.181
+ 192.168.100.182

VIP
---
+ 192.168.100.180
---

注:Master节点使用Keepalived+Haproxy进行高可用负载均衡
+ Keepalived对Master节点的kube-apiserver提供高可用VIP服务
+ Haproxy监听VIP并连接kube-apiserver提供负载均衡服务，所有组件通过开放的8443端口访问

---
Node节点
---
+ 192.168.100.183
+ 192.168.100.184
+ 192.168.100.185
---
规划
---
1.所有节点均部署etcd
2.在ansible主机生成ssl证书，并将所有证书放在了/root/ssl下
3.kubernetes二进制包以及压缩后的文件夹均位于/root/下
使用ansible-playbook命令部署集群
---
```bash
# ansible-playbook k8s.yaml
```
---
查看集群状况
---
```bash
# ansible 192.168.100.181 -a "etcdctl --endpoints=https://192.168.100.181:2379 ls /kube/network/subnets"
192.168.100.181 | SUCCESS | rc=0 >>
/kube/network/subnets/10.244.95.0-24
/kube/network/subnets/10.244.72.0-24
/kube/network/subnets/10.244.62.0-24
# ansible 192.168.100.181 -a "kubectl get cs"
192.168.100.181 | SUCCESS | rc=0 >>
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-1               Healthy   {"health":"true"}   
etcd-4               Healthy   {"health":"true"}   
etcd-0               Healthy   {"health":"true"}   
etcd-3               Healthy   {"health":"true"}   
etcd-2               Healthy   {"health":"true"}   
# ansible 192.168.100.181 -a "kubectl get nodes"
192.168.100.181 | SUCCESS | rc=0 >>
NAME      STATUS    ROLES     AGE       VERSION
node01    Ready     <none>    1h        v1.11.1
node02    Ready     <none>    1h        v1.11.1
node03    Ready     <none>    1h        v1.11.1
