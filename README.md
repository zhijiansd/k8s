---
使用ansible部署kubernetes集群
---
Master节点
---
+192.168.100.181
+192.168.100.182

---
VIP
---
192.168.100.180
---

注:Master节点使用Keepalived+Haproxy进行高可用负载均衡
+Keepalived对Master节点的kube-apiserver提供高可用VIP服务
+Haproxy监听VIP并连接kube-apiserver提供负载均衡服务，所有组件通过开放的8443端口访问

---
Node节点
---
+192.168.100.183
+192.168.100.184
+192.168.100.185
---
