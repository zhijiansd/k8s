
# 使用ansible部署kubernetes集群
---
Master节点
---
+ 192.168.100.181
+ 192.168.100.182

VIP
---
+ 192.168.100.180
---

注: Master节点使用Keepalived+Haproxy进行高可用负载均衡
+ Keepalived对Master节点的kube-apiserver提供高可用VIP服务
+ Haproxy监听VIP并连接kube-apiserver提供负载均衡服务，所有组件通过开放的8443端口访问(即kube-apiserver为192.168.100.180:8443)

---
Node节点
---
+ 192.168.100.183
+ 192.168.100.184
+ 192.168.100.185
---
规划
---
1. 使用centos 7.4版本制作
2. 所有节点均部署etcd，版本etcd-v3.3.8
3. 在ansible主机生成ssl证书，并将所有证书放在了/root/ssl下(这里我将所有证书分发至所有节点，但是实际有些证书相应节点并不需要，特此说明)
4. kubernetes二进制包以及压缩后的文件夹均位于/root/下，版本v1.11.1
5. 在node节点部署flannel，版本flannel-v0.10.0
6. keepalived和haproxy部署在master节点，版本分别为keepalived-2.0.2和haproxy-1.5.18
7. 以上规划都能在k8s.yaml文件上有所体现
---
使用ansible-playbook命令部署集群
---
```bash
# git clone https://github.com/zhijiansd/ansible-k8s.git
# mkdir -pv /etc/ansible/roles/
# cp -R ansible-k8s/* /etc/ansible/roles/
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
