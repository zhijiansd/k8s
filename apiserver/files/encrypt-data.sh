#!/bin/bash
config()
{
export ENCRYPT_KEY=$(head -c 32 /dev/urandom | base64)

cat <<EOF > /etc/kubernetes/encrypt-data.yaml
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: key1
          secret: ${ENCRYPT_KEY}
    - identity: {}
EOF
}

##配置加密数据
##复制至其他master
LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`
MASTER1='192.168.100.181'
if [ $LOCAL_IP == $MASTER1 ];
then
    config
    scp /etc/kubernetes/encrypt-data.yaml root@master2:/etc/kubernetes/
fi

