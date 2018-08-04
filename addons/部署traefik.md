---
下载部署traefik所需yaml文件
---
```bash
# wget https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik-rbac.yaml
# wget https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik-ds.yaml
# wget https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/ui.yaml
```
---
配置Basic身份验证
---
+ 创建一个包含用户名admin和MD5密码的秘钥文件auth
```bash
# yum -y install httpd
# htpasswd -c auth admin              
New password: 
Re-type new password: 
Adding password for user admin
```
+ 创建secret
```bash
# kubectl create secret generic mysecret --from-file auth --namespace=kube-system      
# kubectl -n kube-system get secret mysecret
NAME       TYPE      DATA      AGE
mysecret   Opaque    1         40s
# kubectl -n kube-system describe secret mysecret
Name:         mysecret
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
auth:  44 bytes
```
---
添加默认TLS认证入口
---
+ 生成证书和密钥
```bash
# openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=traefik-ui.io"
Generating a 2048 bit RSA private key
.................+++
................................................................+++
writing new private key to 'tls.key'
-----
# ls tls*
tls.crt  tls.key
```
+ 创建Secret
```bash
# kubectl -n kube-system create secret tls traefik-ui-tls-cert --key=tls.key --cert=tls.crt
secret/traefik-ui-tls-cert created
# kubectl get secret -n kube-system traefik-ui-tls-cert
NAME                  TYPE                DATA      AGE
traefik-ui-tls-cert   kubernetes.io/tls   2         26s
# kubectl describe secret -n kube-system traefik-ui-tls-cert
Name:         traefik-ui-tls-cert
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Type:  kubernetes.io/tls

Data
====
tls.crt:  1107 bytes
tls.key:  1704 bytes
```
注:密钥必须有两个名为tls.key和tls.crt的条目

+ 配置入口点
```bash
# vim traefik.toml 
defaultEntryPoints = ["http","https"]
insecureskipverify = true
[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
      entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
      [[entryPoints.https.tls.certificates]]
      CertFile = "/ssl/tls.crt"
      KeyFile = "/ssl/tls.key"
```
注:
1.如上定义了两个入口点，http 和 https	  
2.http 监听 80 端口， https 监听 443 端口
3.通过提供一个证书和一个密钥在 https 中开启SSL
4.转发所有的 http 入口点请求到 https入口点
5.insecureSkipVerify :
  如果设置为true，则后端将接受无效的SSL证书。
  这将禁用中间人攻击的检测，因此只能用于安全的后端网络。
  
+ 创建ConfigMap	  
```bash
# kubectl -n kube-system create configmap traefik --from-file=traefik.toml
configmap/traefik created
# kubectl get configmap -n kube-system traefik
NAME      DATA      AGE
traefik   1         21s
# kubectl describe configmap -n kube-system traefik
Name:         traefik
Namespace:    kube-system
Labels:       <none>
Annotations:  <none>

Data
====
traefik.toml:
----
defaultEntryPoints = ["http","https"]
insecureskipverify = true
[entryPoints]
  [entryPoints.http]
  address = ":80"
    [entryPoints.http.redirect]
      entryPoint = "https"
  [entryPoints.https]
  address = ":443"
    [entryPoints.https.tls]
      [[entryPoints.https.tls.certificates]]
      CertFile = "/ssl/tls.crt"
      KeyFile = "/ssl/tls.key"

Events:  <none>
```
---
重新配置 DaemonSet
---
```bash
# vim traefik-ds.yaml 
---
kind: DaemonSet
apiVersion: extensions/v1beta1
metadata:
  name: traefik-ingress-controller
  namespace: kube-system
  labels:
    k8s-app: traefik-ingress-lb
spec:
  template:
    metadata:
      labels:
        k8s-app: traefik-ingress-lb
        name: traefik-ingress-lb
    spec:
      serviceAccountName: traefik-ingress-controller
      terminationGracePeriodSeconds: 60
      volumes:
      - name: ssl
        secret:
          secretName: traefik-ui-tls-cert
      - name: config
        configMap:
          name: traefik
      containers:
      - image: 192.168.100.100/library/traefik
        name: traefik-ingress-lb
        volumeMounts:
        - mountPath: "/ssl"
          name: "ssl"
        - mountPath: "/config"
          name: "config"
        ports:
        - name: http
          containerPort: 80
          hostPort: 80
        - name: https
          containerPort: 443
          hostPort: 443
        - name: admin
          containerPort: 8080
          hostPort: 8080
        securityContext:
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
        args:
        - --api
        - --configfile=/config/traefik.toml
        - --kubernetes
        - --logLevel=INFO
---
```
---
重新配置 UI
---
```bash
# vim ui.yaml 
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: traefik-web-ui
  namespace: kube-system
  annotations:
    kubernetes.io/ingress.class: traefik
    ingress.kubernetes.io/auth-type: "basic"
    ingress.kubernetes.io/auth-secret: "mysecret"
spec:
  rules:
  - host: traefik-ui.io
    http:
      paths:
      - path: /
        backend:
          serviceName: traefik-web-ui
          servicePort: web
  tls:
   - secretName: traefik-ui-tls-cert
---
```
---
部署traefik
---
```bash
# kubectl create -f .
serviceaccount/traefik-ingress-controller created
daemonset.extensions/traefik-ingress-controller created
service/traefik-ingress-service created
clusterrole.rbac.authorization.k8s.io/traefik-ingress-controller created
clusterrolebinding.rbac.authorization.k8s.io/traefik-ingress-controller created
service/traefik-web-ui created
ingress.extensions/traefik-web-ui created
```
+ 查看Pod
```bash
# kubectl get pod -n kube-system | grep traefik
traefik-ingress-controller-2qj5g   1/1       Running   0          47s
traefik-ingress-controller-n2b2w   1/1       Running   0          47s
traefik-ingress-controller-tqrx4   1/1       Running   0          47s
```
+ 查看traefik版本
```bash
# kubectl exec -it traefik-ingress-controller-2qj5g -n kube-system /traefik version
Version:      v1.6.5
Codename:     tetedemoine
Go version:   go1.10.3
Built:        2018-07-10_03:54:03PM
OS/Arch:      linux/amd64
```
+ 查看ingress和service
```bash
# kubectl get ing -n kube-system traefik-web-ui
NAME             HOSTS           ADDRESS   PORTS     AGE
traefik-web-ui   traefik-ui.io             80, 443   1m
# kubectl get service -n kube-system | grep traefik
traefik-ingress-service   ClusterIP   10.244.67.143   <none>        80/TCP,8080/TCP   1m
traefik-web-ui            ClusterIP   10.244.43.185   <none>        80/TCP            1m
```

