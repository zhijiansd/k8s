## 下载配置文件

```bash
wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

## 修改配置文件

```bash
# vim recommended.yaml 
---

kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 40000
  selector:
    k8s-app: kubernetes-dashboard

---
          args:
            - --auto-generate-certificates=false
            - --authentication-mode=token
            - --namespace=kubernetes-dashboard
            - --tls-cert-file=dashboard.pem
            - --tls-key-file=dashboard-key.pem
---
```

> 注:这里的配置是基于自签名证书进行配置的(该自签名证书在该分支的脚本文件中已共同生成)

## 部署kubernetes-dashboard

```bash
# kubectl create ns kubernetes-dashboard
namespace/kubernetes-dashboard created
# kubectl create secret generic kubernetes-dashboard-certs --from-file=/etc/ssl/kubernetes/ -n kubernetes-dashboard
secret/kubernetes-dashboard-certs created
# kubectl apply -f recommended.yaml 
namespace/kubernetes-dashboard created
serviceaccount/kubernetes-dashboard created
service/kubernetes-dashboard created
secret/kubernetes-dashboard-certs created
secret/kubernetes-dashboard-csrf created
secret/kubernetes-dashboard-key-holder created
configmap/kubernetes-dashboard-settings created
role.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrole.rbac.authorization.k8s.io/kubernetes-dashboard created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
clusterrolebinding.rbac.authorization.k8s.io/kubernetes-dashboard created
deployment.apps/kubernetes-dashboard created
service/dashboard-metrics-scraper created
deployment.apps/dashboard-metrics-scraper created
```

## 查看kubernetes-dashboard

```bash
# kubectl get pod -n kubernetes-dashboard
NAME                                        READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-747cf6cd4-zxhmc   1/1     Running   0          28h
kubernetes-dashboard-6f7799b677-t9j4l       1/1     Running   0          28h
```

## 配置一个名为admin的用户并赋予其cluster-admin权限

```bash
# vim auth.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kubernetes-dashboard
---  
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin
  namespace: kubernetes-dashboard
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: admin
    namespace: kubernetes-dashboard   
# kubectl apply -f auth.yaml 
serviceaccount/admin created
clusterrolebinding.rbac.authorization.k8s.io/admin created
```

## 截取token

```bash
# kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin | awk '{print $1}')
```

## 登录kubernetes-dashboard

+ 生成PFX证书

```bash
# openssl x509 -in ca.pem -inform PEM -out cert.der -outform DER
# openssl x509 -req -days 3650 -sha1 -extensions v3_ca -signkey ca-key.pem -in ca.csr -out cert.crt 
Signature ok
subject=/C=CN/ST=BeiJing/L=BeiJing/O=k8s/OU=System/CN=kubernetes
Getting Private key
# openssl pkcs12 -export -in cert.crt -inkey ca-key.pem -out  cert.pfx 
Enter Export Password:
Verifying - Enter Export Password:
```

+ 将PFX证书导入到Firefox浏览器中(chrome浏览器导入证书依然会提示问题)

+ 浏览器输入https://nodeip:nodeport即可进入kubernetes-dashboard，之后选择token，输入token即可登录
