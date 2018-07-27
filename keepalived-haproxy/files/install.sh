#!/bin/bash
##安装相应软件包
yum -y install ipvsadm curl gcc openssl-devel libnl3-devel net-snmp-devel libnfnetlink-devel

##编译安装keepalived
wget http://www.keepalived.org/software/keepalived-2.0.2.tar.gz -O /tmp/keepalived-2.0.2.tar.gz
tar -zxvf /tmp/keepalived-2.0.2.tar.gz -C /tmp
cd /tmp/keepalived-2.0.2
./configure --sysconf=/etc --prefix=/usr/local/keepalived
make 
make install
cp /usr/local/keepalived/sbin/keepalived /usr/sbin/

##配置keepalived
MAST=192.168.100.181
BACK=192.168.100.182
VIP=192.168.100.180
LOCAL_IP=`ip addr|grep ens33|grep inet|awk '{print $2}'|cut -c 1-15`

function rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(($RANDOM+50))
    echo $(($num%$max+$min))  
}

if [ $LOCAL_IP == $MAST ];
then
    NUM=$(rand 101 110)
    VRRP=MASTER
    SERVER1=$MAST
    SERVER2=$BACK
elif [ $LOCAL_IP == $BACK ];
then
    NUM=$(rand 90 100)
    VRRP=BACKUP
    SERVER1=$BACK
    SERVER2=$MAST
fi

cat <<EOF > /etc/keepalived/keepalived.conf
! Configuration File for keepalived
global_defs {
    notification_email {
        wangzhijiansd@qq.com
        zhijiansd@163.com
    }
    notification_email_from zhi@zhi.io
        smtp_server 127.0.0.1
        smtp_connect_timeout 30
        router_id LVS_K8S
}
vrrp_script check_haproxy {
    script "/etc/keepalived/check_haproxy.sh"
    interval 2     ##脚本调用时间(默认1秒)
    timeout  2     ##脚本被认为调用失败的时间
    weight  -20     ##优先级(默认为0,范围在-253-253之间)
    fall    5      ##当脚本为OK状态时, 并且最终weight(以track_script中的weight覆盖值为准)>0, 则优先级可以加上weight
    rise    10     ##当脚本为KO状态时, 并且终止的weight(以track_script中的weight覆盖值为准)<0, 则优先级可以减去weight
    user    root   ##在用户/组下运行脚本(默认为用户组)
}
vrrp_instance VI_1 {
    state $VRRP       
    interface ens33
    virtual_router_id 51
    priority $NUM
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass abcd
    }
    virtual_ipaddress {
        $VIP/24
    }
    track_script {
        check_haproxy
    }
}
EOF

##运行 keepalived
systemctl daemon-reload
systemctl start keepalived
systemctl enable keepalived
