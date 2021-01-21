---
部署之前所需配置
---

### kube-apiserver

```bash
--requestheader-allowed-names
--requestheader-client-ca-file=/etc/ssl/kubernetes/ca.pem
--requestheader-extra-headers-prefix=X-Remote-Extra- 
--requestheader-group-headers=X-Remote-Group 
--requestheader-username-headers=X-Remote-User
--enable-aggregator-routing
```

