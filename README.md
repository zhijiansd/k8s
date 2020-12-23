# 使用Ansible部署高可用Kubernetes集群

---
节点规划
---

|    Etcd节点   |   Master节点   |   Node节点    |      VIP      |
|:-------------:|:-------------:|:-------------:|:-------------:|
|192.168.100.136|192.168.100.139|192.168.100.142|               |
|192.168.100.137|192.168.100.140|192.168.100.143|192.168.100.150|
|192.168.100.138|192.168.100.141|192.168.100.144|               |

> 注: Master节点使用Keepalived+Haproxy进行高可用负载均衡
+ Keepalived对Master节点的kube-apiserver提供高可用VIP服务
+ Haproxy监听VIP对kube-apiserver提供负载均衡服务，所有组件通过开放的8443端口访问

---
应用规划
---

|系统版本 |CFSSL版本 |ETCD版本|KeepAlived版本|HaProxy版本 |Kubernetes版本|Containerd版本|Crictl版本|
|:------:|:--------:|:------:|:-----------:|:---------:|:------------:|:------------:|:--------:|
|CentOS 8|  1.5.0   |v3.4.14 |   2.1.5     |   2.3.2   |    v1.19.5   |     1.4.3    |  v1.19.0 |

> 注: 该版将需要更改的的配置进行变量化配置，更改项主要在"defaults/main.yaml"、"tasks/main.yaml"这两个文件中，cfssl安装在ansible主机，kubernetes压缩在ansible主机，其他应用下载压缩包在ansible主机即可。

---
安装ansible
---

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

---
生成SSH认证所需的公钥和私钥文件
---

```bash
ssh-keygen -t rsa -P ''
```

---
复制hosts
---

```bash
ansible all -m copy -a "src=/etc/hosts dest=/etc/hosts"
```

---
签署证书
---

```bash
source cfssl.sh
ansible-playbook ssl.yaml
```

---
部署集群
---

```bash
ansible-playbook k8s.yaml
```

---
查看集群状况
---

```bash
# ansible 192.168.100.136 -a "etcdctl --endpoints=https://192.168.100.136:2379 --cacert=/etc/ssl/etcd/ca.pem --key=/etc/ssl/etcd/etcd-key.pem --cert=/etc/ssl/etcd/etcd.pem -w=table member list"
192.168.100.136 | CHANGED | rc=0 >>
+------------------+---------+-------+------------------------------+------------------------------+------------+
|        ID        | STATUS  | NAME  |          PEER ADDRS          |         CLIENT ADDRS         | IS LEARNER |
+------------------+---------+-------+------------------------------+------------------------------+------------+
| 25d84952513e4c13 | started | etcd3 | https://192.168.100.138:2380 | https://192.168.100.138:2379 |      false |
| 5700b9ecd6ca26d0 | started | etcd2 | https://192.168.100.137:2380 | https://192.168.100.137:2379 |      false |
| 8c08a828e17afa88 | started | etcd1 | https://192.168.100.136:2380 | https://192.168.100.136:2379 |      false |
+------------------+---------+-------+------------------------------+------------------------------+------------+

# ansible 192.168.100.139 -a "kubectl cluster-info"
192.168.100.139 | CHANGED | rc=0 >>
Kubernetes master is running at https://192.168.100.150:8443

# ansible 192.168.100.139 -a "kubectl get cs"
192.168.100.139 | CHANGED | rc=0 >>
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok                  
controller-manager   Healthy   ok                  
etcd-0               Healthy   {"health":"true"}   
etcd-2               Healthy   {"health":"true"}   
etcd-1               Healthy   {"health":"true"}   

# ansible 192.168.100.139 -a "kubectl get nodes"
192.168.100.139 | CHANGED | rc=0 >>
NAME    STATUS   ROLES    AGE   VERSION
node1   Ready    <none>   14h   v1.19.5
node2   Ready    <none>   14h   v1.19.5
node3   Ready    <none>   14h   v1.19.5
```

---
清理集群
---

```bash
ansible-playbook clean-cluster.yaml
```
