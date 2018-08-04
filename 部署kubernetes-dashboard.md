---
配置证书
---
+ 配置证书
```bash
# vim dashboard_csr.json
{
    "CN": "dashboard",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "hosts": [
      "127.0.0.1",
      "192.168.100.180",
      "192.168.100.181",
      "192.168.100.182",
      "192.168.100.183",
      "192.168.100.184",
      "192.168.100.185"
    ],
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "k8s",
        "OU": "dashboard"
      }
    ]
}
```
+ 生成 kubernetes-dashboard 客户端证书和私钥
```bash
# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca_config.json -profile=kubernetes  dashboard_csr.json | cfssljson -bare dashboard
```
+ 创建secret
```bash
# kubectl create secret generic kubernetes-dashboard-certs --from-file=/etc/kubernetes/ssl/ -n kube-system
secret/kubernetes-dashboard-certs created
# kubectl -n kube-system describe secret kubernetes-dashboard-certs 
```
---
下载kubernetes-dashboard配置文件
---
```bash
# wget https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
```
---
更改kubernetes-dashboard配置文件
---
```bash
# vim kubernetes-dashboard.yaml
# ------------------- Dashboard Deployment ------------------- #
args:
          - --auto-generate-certificates=false
          - --authentication-mode=token,basic
          - --tls-cert-file=dashboard.pem
          - --tls-key-file=dashboard-key.pem
		  
# ----------------------------------------------------------- #
```
---
部署kubernetes-dashboard
---
```bash
# kubectl apply -f kubernetes-dashboard.yaml 
secret/kubernetes-dashboard-certs created
serviceaccount/kubernetes-dashboard created
role.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
deployment.apps/kubernetes-dashboard created
service/kubernetes-dashboard created
# kubectl -n kube-system get pod -o wide |grep dash
kubernetes-dashboard-855cc56f8f-l2fm6   1/1  Running  0   3    10.244.67.2     node01
```
---
配置traefik代理kubernetes-dashboard
---
```bash
# vim k8s.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubernetes-dashboard
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
  - host: "k8s.zhi.io"
    http:
      paths:
      - backend:
          serviceName: kubernetes-dashboard
          servicePort: 443
# kubectl create -f k8s.yaml 
ingress.extensions/kubernetes-dashboard created
# kubectl -n kube-system get ing kubernetes-dashboard
NAME                   HOSTS        ADDRESS   PORTS     AGE
kubernetes-dashboard   k8s.zhi.io             80        12s
```
配置hosts后，浏览器输入k8s.zhi.io后可以使用如下授权登录:
1. Kubeconfig
1. 令牌
+ 配置一个admin-user的用户并赋予其cluster-admin权限
```bash
# vim admin-user.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
# kubectl create -f admin-user.yaml 
serviceaccount/admin-user created
clusterrolebinding.rbac.authorization.k8s.io/admin-user created
```
+ 截取token,复制至kubernetes-dashboard使用令牌登陆
```bash
# kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```
1. basic基本身份验证
输入在配置apiserver时--basic-auth-file下的用户名和密码即可登录
