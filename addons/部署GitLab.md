---
配置都是从如下项目copy过来的(配置已放在gitlab文件夹下)，感谢:
---
[github.com/sameersbn/docker-gitlab](https://github.com/sameersbn/docker-gitlab) 
---
1.部署Namespace
---
```bash
kubectl apply -f gitlab-ns.yml 
```
---
2.部署Redis
---
```bash
kubectl create -f redis-svc.yml 
kubectl create -f redis-rc.yml 
```
---
4.部署PostgreSQL
---
```bash
kubectl create -f postgresql-svc.yml 
kubectl create -f postgresql-rc.yml 
```
---
5.部署GitLab
---
+ 创建 configmap
---
```bash
# kubectl -n gitlab create configmap gitlab-rb --from-file=gitlab.rb
# kubectl -n gitlab describe configmap gitlab-rb
Name:         gitlab-rb
Namespace:    gitlab
Labels:       <none>
Annotations:  <none>

Data
====
gitlab.rb:
----
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = "wangzhijiansd@qq.com"
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "wangzhijiansd@qq.com"
gitlab_rails['smtp_password'] = "zputsplmlklmbdad"
gitlab_rails['smtp_domain'] = "zhi.io"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_openssl_verify_mode'] = "peer"
gitlab_rails['smtp_tls'] = true

prometheus['monitor_kubernetes'] = true
prometheus['listen_address'] = '0.0.0.0:9090'
node_exporter['enable'] = true
redis_exporter['enable'] = true
postgres_exporter['enable'] = true
gitlab_monitor['enable'] = true

Events:  <none>
```

