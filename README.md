# 使用Ansible部署Kubernetes集群

## 节点规划

|    Etcd节点   |   Master节点   |   Node节点    |      VIP      |
|:--------------|--------------:|--------------:|:-------------:|
|192.168.100.136|192.168.100.139|192.168.100.142|               |
|192.168.100.137|192.168.100.140|192.168.100.143|192.168.100.150|
|192.168.100.138|192.168.100.141|192.168.100.144|               |

> 注: Master节点使用Keepalived+Haproxy进行高可用负载均衡
+ Keepalived对Master节点的kube-apiserver提供高可用VIP服务
+ Haproxy监听VIP对kube-apiserver提供负载均衡服务，所有组件通过开放的8443端口访问

### 应用规划
|系统版本 |Cfssl版本 |Etccd版本|Flannel版本|Keepalived版本|Haproxy版本|Kubernetes版本|
|:-------|---------:|--------:|----------:|------------:|----------:|:------------:|
|Centos 8|  v1.4.1  | v3.3.18 |  v0.11.0  |   2.0.19    |   2.1.0   |    v1.17.0   |

## 安装ansible

```bash
# yum -y install ansible
# egrep -v "^#|^$" /etc/ansible/hosts
[etcd]
192.168.100.136  hostname=etcd1
192.168.100.137  hostname=etcd2
192.168.100.138  hostname=etcd3
[master]
192.168.100.139  hostname=master1
192.168.100.140  hostname=master2
192.168.100.141  hostname=master3
[node]
192.168.100.142  hostname=node1
192.168.100.143  hostname=node2
192.168.100.144  hostname=node3
[etcd:vars] 
ansible_ssh_user="root" 
ansible_ssh_pass="wangzhijian"
[master:vars] 
ansible_ssh_user="root" 
ansible_ssh_pass="wangzhijian"
[node:vars] 
ansible_ssh_user="root" 
ansible_ssh_pass="wangzhijian"
```

## 生成SSH认证所需的公钥和私钥文件

```bash
ssh-keygen -t rsa -P ''
```

## 复制hosts

```bash
ansible all -m copy -a "src=/etc/hosts dest=/etc/hosts"
```

## 签署证书

```bash
source cfssl.sh
ansible-playbook ssl.yaml
```

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
