---
查看 Kubernetes-Dashboard
---

```bash
# kubectl get pod -n kubernetes-dashboard
NAME                                         READY   STATUS    RESTARTS   AGE
dashboard-metrics-scraper-7d8b968899-8lmjb   1/1     Running   0          11h
kubernetes-dashboard-6df6d55fc6-rwln4        1/1     Running   0          11h
# kubectl get service -n kubernetes-dashboard
NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
dashboard-metrics-scraper   ClusterIP   10.244.208.221   <none>        8000/TCP        12h
kubernetes-dashboard        NodePort    10.244.186.22    <none>        443:38443/TCP   12h
```

---
截取 Token
---

```bash
# kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin | awk '{print $1}')
```

---
登录 Kubernetes-Dashboard
---
+ 浏览器输入https://nodeip:nodeport即可进入kubernetes-dashboard，之后选择token，输入token即可登录
